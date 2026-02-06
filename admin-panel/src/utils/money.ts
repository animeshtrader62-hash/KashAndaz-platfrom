export function formatInr(amount: number): string {
  try {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amount)
  } catch {
    return `₹ ${amount}`
  }
}
