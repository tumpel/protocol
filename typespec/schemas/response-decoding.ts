import { z } from "zod";

const unrecognised = "Unrecognised";
const unknownEnum = z.string().transform((): typeof unrecognised => unrecognised);
export const unrecognisedTag: z.ZodLiteral<typeof unrecognised> = z.literal(unrecognised);

export function openEnum<Schema extends z.ZodType<string | number>>(
  known: Schema,
): z.ZodUnion<readonly [Schema, typeof unknownEnum]> {
  return z.union([known, unknownEnum]);
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function openUnion<Schema extends z.ZodDiscriminatedUnion>(
  schema: Schema,
  tags: readonly string[],
): z.ZodPreprocess<Schema> {
  const known = new Set(tags);
  const discriminator = schema.def.discriminator;
  return z.preprocess((value) => {
    if (!isObject(value)) return value;
    const tag = value[discriminator];
    if (typeof tag !== "string" || known.has(tag)) return value;
    return { ...value, [discriminator]: unrecognised };
  }, schema);
}

export function containsUnrecognised(schema: z.core.$ZodType, value: unknown): boolean {
  if (schema === unknownEnum || schema === unrecognisedTag) return value === unrecognised;
  if (schema instanceof z.ZodLazy || schema instanceof z.ZodOptional || schema instanceof z.ZodNullable) {
    return containsUnrecognised(schema.unwrap(), value);
  }
  if (schema instanceof z.ZodPipe) return containsUnrecognised(schema.out, value);
  if (schema instanceof z.ZodArray && Array.isArray(value)) {
    return value.some((item) => containsUnrecognised(schema.element, item));
  }
  if (schema instanceof z.ZodObject && isObject(value)) {
    return Object.entries(schema.shape).some(([key, field]) => containsUnrecognised(field, value[key]));
  }
  if (schema instanceof z.ZodRecord && isObject(value)) {
    return Object.values(value).some((item) => containsUnrecognised(schema.valueType, item));
  }
  if (schema instanceof z.ZodDiscriminatedUnion && isObject(value)) {
    const discriminator = schema.def.discriminator;
    const option = schema.options.find(
      (option) =>
        option instanceof z.ZodObject && z.safeParse(option.shape[discriminator], value[discriminator]).success,
    );
    return option !== undefined && containsUnrecognised(option, value);
  }
  if (schema instanceof z.ZodUnion) {
    const option = schema.options.find((option) => z.safeParse(option, value).success);
    return option !== undefined && containsUnrecognised(option, value);
  }
  return false;
}
