"""GoToMoney brand layer (branch `gotomoney`): display-only renames applied to rendered output.

Kept in one module so an upstream merge conflicts here, not across every template string.
Engine credit stays where it is attributed: "Jev, TypeSafe..." and "(Jev, experimental)".
"""
import re

ACTION_PREFIX = "RC"  # action IDs read RC-001 (Readiness Check) instead of JEV-001
_JEV_WORD = re.compile(r"\bJev(?:'s)?\b(?!, (?:TypeSafe|experimental))")


def text(s: str) -> str:
    """Replace the engine name with a neutral label in client-facing prose."""
    s = re.sub(r"\bJEV-(\d{3})\b", rf"{ACTION_PREFIX}-\1", s)
    for a, b in (("Jev judged", "Model-judged"), ("Jev judges", "Model judges"), ("Pages Jev would", "Pages the model would"),
                 ("How Jev reads", "How the model reads"), ("How sure Jev was", "How sure the model was")):
        s = s.replace(a, b)
    s = _JEV_WORD.sub(lambda m: "the model's" if m.group(0).endswith("'s") else "\x00", s)
    # "Jev trust averaged", "Jev P(...)", "Jev relevance": adjective use -> "model"; anything else -> "the model"
    s = re.sub(r"(^|[>(]\s*|[.:]\s+)\x00(?= (?:[a-z]|P\())", r"\1Model", s, flags=re.M)  # sentence start
    s = re.sub(r"\x00(?= (?:[a-z]|P\())", "model", s)
    return s.replace("\x00", "the model")


if __name__ == "__main__":
    assert text("JEV-012 · Jev judged") == "RC-012 · Model-judged"
    assert text("A judgment model (Jev, TypeSafe's System One)") == "A judgment model (Jev, TypeSafe's System One)"
    assert text("<h3>Judgment model (Jev, experimental)</h3>") == "<h3>Judgment model (Jev, experimental)</h3>"
    assert text("This is Jev's editorial judgment") == "This is the model's editorial judgment"
    assert text("model typesafe/jev-1.13 on jev-seo 0.1.1") == "model typesafe/jev-1.13 on jev-seo 0.1.1"
    assert text("Jev helpfulness averaged 0.19") == "Model helpfulness averaged 0.19"
    assert text("Jev P(opens with the point) averaged") == "Model P(opens with the point) averaged"
    assert text("Pages Jev would rewrite") == "Pages the model would rewrite"
    assert text("70% Jev judgment") == "70% model judgment"
    assert text("x: Jev trust averaged") == "x: Model trust averaged"
    print("brand self-test OK")
