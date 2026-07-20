// ESM wrapper for signature_pad UMD module.
// The UMD build attaches to globalThis.SignaturePad but provides no
// ES module default export, so importmaps can't use it directly.
import "signature_pad"

export default window.SignaturePad
