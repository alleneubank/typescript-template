import { expect, test } from 'bun:test'
import { VERSION } from './index'

test('VERSION is the template version', () => {
  expect(VERSION).toBe('0.0.0')
})
