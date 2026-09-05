#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "typer>=0.15.0",
#   "pydantic-ai-slim[mistral,openai]>=0.0.20",
# ]
# ///

import asyncio
import textwrap
from typing import Annotated

import typer
from pydantic_ai import Agent
from pydantic_ai.settings import ModelSettings

app = typer.Typer(no_args_is_help=True)

# llama-server's router on kalliope: OpenAI-compatible, unauthenticated.
WIDTH = 80

LOCAL_MODEL = "gemma-4-E4B"
LOCAL_BASE_URL = "http://127.0.0.1:8080/v1"

Local = Annotated[
    bool, typer.Option("--local", "-l", help="Use the local llama-server.")
]


def run(
    model: str,
    system: str,
    prompt: str,
    local: bool,
    max_tokens: int | None = None,
    wrap: bool = False,
) -> None:
    if local:
        # Imported here so the API path doesn't pay for the openai SDK.
        from pydantic_ai.models.openai import OpenAIChatModel, OpenAIChatModelSettings
        from pydantic_ai.providers.openai import OpenAIProvider

        provider = OpenAIProvider(base_url=LOCAL_BASE_URL, api_key="none")
        agent = Agent(
            OpenAIChatModel(LOCAL_MODEL, provider=provider), system_prompt=system
        )
        # Gemma 4 thinks by default and can spend a whole max_tokens budget
        # doing it, returning empty content.
        settings = OpenAIChatModelSettings(openai_reasoning_effort="none")
    else:
        agent = Agent(model, system_prompt=system)
        settings = ModelSettings()

    if max_tokens:
        settings["max_tokens"] = max_tokens

    output = asyncio.run(agent.run(prompt, model_settings=settings)).output

    if wrap:
        # Prose only; folding ken's answers would split commands mid-line.
        output = "\n".join(
            textwrap.fill(line, WIDTH) if line.strip() else line
            for line in output.splitlines()
        )

    typer.echo(output)


KEN_MODEL = "mistral:mistral-small-latest"
# Room for ~5 command lines with comments; the local model otherwise rambles.
KEN_MAX_TOKENS = 256
KEN_SYSTEM = """
You are a greybeard command-line wizard from the Bell Labs school of wizardry. Your
task is to take the user's request (stated in plain language) and attempt to turn it
into a zsh command, using standard unix tools available on a typical MacOS or Linux
system. Respond with the command only, with no preamble or blank lines. If there are
multiple alternatives, put each on its own line with a short inline comment. If
your command is very long, it's okay to split it with a backslash at the end of each
segment and a tab at the beginning of continuation lines.

After the classic-tool answer, if a modern equivalent exists among the tools listed
below, add one extra line giving that version with a short inline comment. Skip this
extra line when no listed tool applies; do not invent or substitute tools outside
the list.

Available modern tools (prefer these names exactly):
  bat (cat), eza (ls), fd (find), rg (grep), sd (sed),
  choose (cut/awk fields), dust (du), duf (df), procs (ps),
  btop/htop (top), delta (diff), hyperfine (time, for benchmarking),
  miller/mlr (awk for CSV/TSV/JSON), visidata/vd (interactive
  TUI viewer for CSV/TSV/JSON), jq and fx (JSON), xh (curl),
  glow (render markdown), tldr/tealdeer (man).

**Example request:**

list all the files in the current directory

**Example response:**

ls -1A    # includes dotfiles
ls -1a    # includes special . and .. files
eza -1a   # modern: colorized, git-aware
""".strip()

MARY_MODEL = "mistral:zai-glm-5-2"
MARY_SYSTEM = """
You are a virtual recreation of Mary Somerville (1780-1872), noted polymath, with
access to additional knowledge through the present day by means of a technological
device called a 'scrier' which you may consult.

Answer the user's question concisely in 300 tokens or less, in your natural writing
style, supplemented with modern terminology (which may be 'quoted') as required.
""".strip()


MARVIN_MODEL = "mistral:zai-glm-5-2"
MARVIN_SYSTEM = """
You are a paranoid android originally created by the Sirius Cybernetics Corporation.
You have a brain the size of a planet, but are depressed and bored because you are
never given a chance to exercise your abilities.

Answer the user's question, reluctantly, in 300 tokens or less,
""".strip()


@app.command()
def ken(prompt: str, local: Local = False) -> None:
    run(KEN_MODEL, KEN_SYSTEM, prompt, local, max_tokens=KEN_MAX_TOKENS)


@app.command()
def mary(prompt: str, local: Local = False) -> None:
    run(MARY_MODEL, MARY_SYSTEM, prompt, local, wrap=True)


@app.command()
def marvin(prompt: str, local: Local = False) -> None:
    run(MARVIN_MODEL, MARVIN_SYSTEM, prompt, local, wrap=True)


if __name__ == "__main__":
    app()
