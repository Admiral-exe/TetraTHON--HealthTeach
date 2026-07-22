from langchain_core.messages import HumanMessage, AIMessage, BaseMessage

def format_langchain_context_window(chat_history: list[dict], k: int = 3) -> str:
    """
    Uses LangChain message abstractions to build a trimmed conversation history window.
    Slices the last k conversation turns (up to 2*k messages: user + assistant turns).
    Returns a formatted clinical conversation transcript block for the LLM.
    """
    if not chat_history:
        return ""

    # Convert incoming dictionary turns to LangChain message objects
    messages: list[BaseMessage] = []
    for item in chat_history:
        role = str(item.get("sender") or item.get("role") or "user").lower()
        content = str(item.get("text") or item.get("content") or "")

        if not content.strip():
            continue

        if role in ["user", "human"]:
            messages.append(HumanMessage(content=content))
        else:
            messages.append(AIMessage(content=content))

    # Apply window slicing for last k conversations (max 2 * k messages)
    max_messages = k * 2
    window_messages = messages[-max_messages:] if len(messages) > max_messages else messages

    if not window_messages:
        return ""

    transcript_lines = ["\n[LANGCHAIN CONVERSATION MEMORY (LAST 3 TURNS)]:"]
    for msg in window_messages:
        prefix = "PATIENT" if isinstance(msg, HumanMessage) else "CLINICAL AI"
        transcript_lines.append(f"{prefix}: {msg.content}")

    return "\n".join(transcript_lines) + "\n"
