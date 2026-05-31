/**
 * Session title auto-generation via AI summarization.
 *
 * After N user turns (default 3), asynchronously calls the current model
 * to generate a short descriptive title (≤50 chars) and stores it in
 * `autoTitle` on the session entry. Designed to be fire-and-forget so it
 * never blocks the conversation.
 */

import type { SessionEntry } from "../config/sessions/types.js";
import type { OpenClawConfig } from "../config/types.openclaw.js";
import { logVerbose } from "../globals.js";

const DEFAULT_TURNS_BEFORE_TITLE = 3;
const DEFAULT_MAX_CHARS = 50;

/** Minimal prompt to generate a session title from the first few messages. */
function buildTitlePrompt(firstMessages: string[], maxChars: number): string {
  const conversation = firstMessages
    .map((msg, i) => `Message ${i + 1}: ${msg.slice(0, 300)}`)
    .join("\n");

  return `Generate a very short, concise title (maximum ${maxChars} characters) that captures the main topic of this conversation. Return ONLY the title text, nothing else — no quotes, no prefix, no explanation.

Conversation:
${conversation}

Title:`;
}

export type TitleGeneratorContext = {
  /** First few user messages from the session transcript. */
  firstMessages: string[];
  /** Current session entry. */
  sessionEntry: SessionEntry;
  /** Session key for store lookups. */
  sessionKey: string;
  /** Active OpenClaw config snapshot. */
  cfg: OpenClawConfig;
  /** Callback to persist the updated session entry to the store. */
  persistEntry: (sessionKey: string, entry: Partial<SessionEntry>) => Promise<void>;
  /** Callback to call the LLM with a prompt and get back text. */
  callModel: (prompt: string, model?: string) => Promise<string | undefined>;
};

/**
 * Returns true if an auto-title should be generated for this session.
 */
export function shouldGenerateTitle(entry: SessionEntry, cfg: OpenClawConfig): boolean {
  const titleCfg = cfg.session?.sessionTitle;
  if (titleCfg?.enabled === false) return false;
  if (entry.autoTitle && entry.autoTitle.trim().length > 0) return false;

  const turnsBefore = titleCfg?.turnsBeforeTitle ?? DEFAULT_TURNS_BEFORE_TITLE;
  const currentTurns = entry.autoTitleTurnsCount ?? 0;
  return currentTurns >= turnsBefore;
}

/**
 * Increments the user-turn counter on the session entry.
 * Call this after each user message in the session.
 */
export function incrementTitleTurnCount(entry: SessionEntry): Partial<SessionEntry> {
  const next = (entry.autoTitleTurnsCount ?? 0) + 1;
  return { autoTitleTurnsCount: next, updatedAt: Date.now() };
}

/**
 * Generates a session title asynchronously. This is designed to be called
 * in a fire-and-forget manner after a user turn completes.
 */
export async function generateSessionTitle(ctx: TitleGeneratorContext): Promise<void> {
  const titleCfg = ctx.cfg.session?.sessionTitle;
  const maxChars = titleCfg?.maxChars ?? DEFAULT_MAX_CHARS;

  if (!ctx.firstMessages || ctx.firstMessages.length === 0) {
    logVerbose(`[session-title] No messages available for session ${ctx.sessionKey}`);
    return;
  }

  const prompt = buildTitlePrompt(ctx.firstMessages, maxChars);

  try {
    const title = await ctx.callModel(prompt);
    if (title && title.trim().length > 0) {
      const trimmed = title.trim().slice(0, maxChars);
      logVerbose(`[session-title] Generated title "${trimmed}" for session ${ctx.sessionKey}`);
      await ctx.persistEntry(ctx.sessionKey, {
        autoTitle: trimmed,
        autoTitleGeneratedAt: Date.now(),
      });
    }
  } catch (err) {
    logVerbose(
      `[session-title] Failed to generate title for session ${ctx.sessionKey}: ${String(err)}`,
    );
  }
}
