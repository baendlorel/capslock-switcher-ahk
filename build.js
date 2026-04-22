// C:\\Program Files\\AutoHotkey\\Compiler\\Ahk2Exe.exe /in capslock-switcher.ahk /out capslock-switcher.exe

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const POSSIBLE_AHK_PATHS = [
  ['Program Files', 'AutoHotkey', 'Compiler', 'Ahk2Exe.exe'],
  ['Program Files (x86)', 'utoHotkey', 'Compiler', 'Ahk2Exe.exe'],
];
const POSSIBLE_DISK = [
  'C:',
  'D:',
  'E:',
  'F:',
  'G:',
  'H:',
  'I:',
  'J:',
  'K:',
  'L:',
  'M:',
  'N:',
  'O:',
  'P:',
  'Q:',
  'R:',
  'S:',
  'T:',
  'U:',
  'V:',
  'W:',
  'X:',
  'Y:',
  'Z:',
];

const POSSIBLE_AHK_PATHS_WITH_DISK = POSSIBLE_DISK.reduce((prev, cur) => {
  const withDisk = POSSIBLE_AHK_PATHS.map((p) => [cur, ...p]);
  prev.push(...withDisk);
  return prev;
}, []).map((p) => path.join(...p));

function getAhk() {
  const ahkPath = path.resolve('ahk-path.txt');
  if (fs.existsSync(ahkPath)) {
    const ahk = fs.readFileSync(ahkPath, 'utf-8').trim();
    if (!ahk.includes('[Compiler Path Not Found]')) {
      return ahk;
    }
  }

  let ahk = null;
  console.log(POSSIBLE_AHK_PATHS_WITH_DISK);
  for (const possibleAhkPath of POSSIBLE_AHK_PATHS_WITH_DISK) {
    if (fs.existsSync(possibleAhkPath)) {
      ahk = possibleAhkPath;
      fs.writeFileSync(ahkPath, ahk);
      break;
    }
  }

  if (!ahk) {
    fs.writeFileSync(
      ahkPath,
      '[Compiler Path Not Found] 请将AutoHotKey的编译器的绝对地址写在本文件中。 ...\\AutoHotkey\\Compiler\\Ahk2Exe.exe here',
    );
  }

  return ahk;
}

function getAllAhkFiles(dir) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...getAllAhkFiles(full));
    } else if (entry.name.endsWith('.ahk')) {
      results.push(full);
    }
  }
  return results;
}

function toggleVersionPlaceholder(pkgDir, version, state) {
  for (const file of getAllAhkFiles(pkgDir)) {
    const content = fs.readFileSync(file, 'utf-8');
    const updated =
      state === 'on' ? content.replace('__APP_VERSION__', version) : content.replace(version, '__APP_VERSION__');
    if (content !== updated) {
      fs.writeFileSync(file, updated);
    }
  }
}

function ensureBinDir() {
  const binDir = path.resolve('bin');
  if (!fs.existsSync(binDir)) {
    fs.mkdirSync(binDir);
  }
}

const ahkMap = new Map([
  [undefined, 'capslock-switcher'],
  ['cpu', 'cpu-monitor'],
]);
function build() {
  const who = ahkMap.get(process.argv[2]) ?? process.argv[2];
  const ahk = getAhk();
  const version = 'v' + JSON.parse(fs.readFileSync(path.resolve('package.json'), 'utf-8')).version;
  const pkgDir = path.resolve('packages', who);
  const source = path.join(pkgDir, who + '.ahk');
  const exe = path.resolve('bin', `${who}-${version}.exe`);
  const icon = path.resolve('assets', who + '.ico');
  console.log(`building [${exe}] through [${ahk}] with icon [${icon}]...`);
  try {
    ensureBinDir();
    toggleVersionPlaceholder(pkgDir, version, 'on');
    execSync(`"${ahk}" /in "${source}" /out "${exe}" /icon "${icon}"`);
  } finally {
    toggleVersionPlaceholder(pkgDir, version, 'off');
  }
}

build();
