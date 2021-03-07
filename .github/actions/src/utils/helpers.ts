export const joinArray = (array1: string[], array2: string[]) => {
  const inner = array1.filter(item => array2.includes(item));
  const outter = [...array1.filter(item => !inner.includes(item)), ...array2.filter(item => !inner.includes(item))]
  return { inner, outter }
}