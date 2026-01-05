import { useMemo } from 'react';

const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

/**
 * Custom hook for UUID validation
 * @param value - The string value to validate as UUID
 * @returns Object containing trimmed value and validation status
 */
export function useUUIDValidation(value: string) {
  const trimmedValue = useMemo(() => value.trim(), [value]);
  const isValid = useMemo(() => UUID_REGEX.test(trimmedValue), [trimmedValue]);

  return { trimmedValue, isValid };
}
