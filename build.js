// C:\\Program Files\\AutoHotkey\\Compiler\\Ahk2Exe.exe /in capslock-switcher.ahk /out capslock-switcher.exe

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const POSSIBLE_AHK_PATHS = [
  ['Program Files', 'AutoHotkey', 'Compiler', 'AutoHotkey.exe'],
  ['Program Files (x86)', 'utoHotkey', 'Compiler', 'AutoHotkey.exe'],
];
const POSSIBLE_DISK = [
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

const POSSIBLE_AHK_PATHS_WITH_DISK = POSSIBLE_DISK.reduce((prev, cur) => {
  const withDisk = POSSIBLE_AHK_PATHS.map((p) => [cur, ...p]);
  prev.push(...withDisk);
}, []).map((p) => path.join(...p));

function getAhk() {
  const ahkPath = path.resolve('ahk-path.txt');
  let ahk = '';
  if (fs.existsSync(ahkPath)) {
    ahk = fs.readFileSync(ahkPath, 'utf-8').trim();
  } else {
    for (const possibleAhkPath of POSSIBLE_AHK_PATHS_WITH_DISK) {
      if (fs.existsSync(possibleAhkPath)) {
        ahk = possibleAhkPath;
        fs.writeFileSync(ahkPath, ahk);
        break;
      }
    }
  }

  if (!ahk) {
    fs.writeFileSync(ahkPath, 'Please put the absolute path to ...\\AutoHotkey\\Compiler\\Ahk2Exe.exe here');
  }

  return ahk;
}

function build() {
  const ahk = getAhk();
  const pkgJson = JSON.parse(fs.readFileSync(path.resolve('package.json'), 'utf-8'));
  const source = path.resolve('capslock-switcher.ahk');
  const exe = path.resolve(`capslock-switcher-v${pkgJson.version}.exe`);
  execSync(`"${ahk}" /in "${source}" /out "${exe}"`);
}

build();
