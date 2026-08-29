import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHiddenVbs } from '../../src/infrastructure/bootstrap.ts';

test('createHiddenVbs emits a valid hidden node launcher', () => {
  const vbs = createHiddenVbs(
    'Gentle-Vanguard-Watchtower-AutoHeal',
    'C:\\Workspace local\\gentle-vanguard\\src\\ops\\watchtower-autoheal-autostart.ts',
    'C:\\Workspace local\\gentle-vanguard',
  );

  assert.match(vbs, /^Set shell = CreateObject\("Wscript\.Shell"\)\r?\n/m);
  assert.match(vbs, /shell\.CurrentDirectory = "C:\\Workspace local\\gentle-vanguard"/);
  assert.match(
    vbs,
    /shell\.Run """[^"\r\n]+node(?:js)?\\node\.exe"" --import tsx ""C:\\Workspace local\\gentle-vanguard\\src\\ops\\watchtower-autoheal-autostart\.ts""", 0, False$/m,
  );
  assert.doesNotMatch(vbs, /powershell|pwsh/i);
  assert.doesNotMatch(vbs, /CreateObject\("Wscript\.Shell"\)\.Run .* --import/);
});
