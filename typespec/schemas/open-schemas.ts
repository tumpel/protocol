import { z } from "zod";

let hits: string[] | undefined;
function record(value: string): "Unrecognised" {
  hits?.push(value);
  return "Unrecognised";
}
export function openEnum<const V extends string | number>(values: readonly V[]): z.ZodType<V | "Unrecognised"> {
  return z.union([z.literal(values), z.string().transform(record)]);
}
type Cases = readonly [z.core.$ZodTypeDiscriminable, ...z.core.$ZodTypeDiscriminable[]];
type Open<V extends Cases> = z.ZodPreprocess<z.ZodDiscriminatedUnion<V>>;
export function openUnion<const V extends Cases>(key: string, variants: V, tags: readonly string[]): Open<V> {
  const normalise = (value: unknown): unknown => {
    if (typeof value !== "object" || value === null || !(key in value)) return value;
    const tag: unknown = Reflect.get(value, key);
    if (typeof tag !== "string" || tags.includes(tag)) return value;
    return { ...value, [key]: record(tag) };
  };
  return z.preprocess(normalise, z.discriminatedUnion(key, variants));
}
export function unionVariant<S extends z.ZodType>(schema: S): z.ZodTransform<z.output<S>> {
  return z.transform((value, context) => {
    const count = hits?.length ?? 0;
    const result = schema.safeParse(value);
    if (result.success) return result.data;
    hits?.splice(count);
    for (const issue of result.error.issues) context.issues.push({ ...issue, input: undefined });
    return z.NEVER;
  });
}
export function decode<S extends z.ZodType>(schema: S, value: unknown): { data: z.output<S>; unrecognised: string[] } {
  const previous = hits;
  hits = [];
  try {
    return { data: schema.parse(value), unrecognised: hits };
  } finally {
    hits = previous;
  }
}
