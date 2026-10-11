import { expect, test } from 'bun:test'
import { getVersion } from './index'

test('getVersion returns the core version', () => {
  expect(getVersion()).toBe('0.0.0')
})
