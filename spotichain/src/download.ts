export async function downloadFile(
  name: string,
  bytes: number[]
): Promise<void> {
  const buffer = new Uint8Array(bytes.length);

  for (let i = 0; i < bytes.length; ++i) {
    buffer[i] = bytes[i];
  }

  await Promise.resolve();

  const blob = new Blob([buffer]);
  const link = document.createElement("a");
  link.href = window.URL.createObjectURL(blob);
  link.download = name;
  link.click();
}
