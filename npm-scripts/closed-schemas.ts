import type { SessionListQuerySchema, SessionStartSchema } from "@tumpel/schemas";
import type { z } from "zod";

type Excludes<T, Value> = Value extends T ? false : true;

export const closedBoxRetention: Excludes<z.infer<typeof SessionStartSchema>["boxRetention"], "Unrecognised"> = true;
export const closedSessionState: Excludes<z.infer<typeof SessionListQuerySchema>["state"], "Unrecognised"> = true;
