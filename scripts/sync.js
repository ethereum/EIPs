#!/usr/local/bin/node

const fs = require('fs')
const path = require('path')

const EN_PATH = path.resolve(__dirname, '../EIPS')
const ZH_PATH = path.resolve(__dirname, '../EIPS/zh')

const enEips = fs.readdirSync(EN_PATH).filter(file => file.includes('eip'))

let count = 0
enEips.forEach(file => {
  const filePath = path.join(ZH_PATH, file)
  if (!fs.existsSync(filePath)) {
    count++
    console.log(`sync ${file}`)
    let fileContent = fs.readFileSync(path.join(EN_PATH, file), 'utf8')
    fileContent = fileContent.replaceAll('(../assets', '(../../assets')
    fs.writeFileSync(path.join(ZH_PATH, file), fileContent)
  }
})

console.log(`sync ${count} eips`)
