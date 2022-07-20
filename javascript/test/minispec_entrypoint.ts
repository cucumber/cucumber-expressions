import glob from 'glob'
import MiniSpec from 'minispec'

async function importTests () {
  for (const testFile of glob.sync('./test/*Test.ts')) {
    console.log(testFile)
    await import(testFile.replace('./test/', './').replace('.ts', '.js'))
  }
}

importTests().then(() => {
  MiniSpec.execute()
})


