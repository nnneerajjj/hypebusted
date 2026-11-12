// Admin-only JS, loaded on Avo pages by app/views/avo/partials/_head.html.erb.
// Avo bundles its own Stimulus application and exposes it as window.Stimulus; controllers register on it.
import { Controller } from "@hotwired/stimulus"

const IMAGE_TYPES = [ "image/png", "image/jpeg", "image/webp", "image/gif" ]

const escapeAttribute = (value) =>
  String(value).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

// Natural width/height of an image file, or null when it can't be decoded.
const measureImage = (file) => new Promise((resolve) => {
  const url = URL.createObjectURL(file)
  const image = new Image()
  image.onload = () => {
    URL.revokeObjectURL(url)
    resolve({ width: image.naturalWidth, height: image.naturalHeight })
  }
  image.onerror = () => {
    URL.revokeObjectURL(url)
    resolve(null)
  }
  image.src = url
})

// "Insert image" controls for the raw HTML textarea on the Avo Post form. Uploads through Avo's attachments
// endpoint (the one its Trix uses) and writes an <action-text-attachment> tag at the caret.
class HtmlImageInsertController extends Controller {
  static targets = [ "file", "caption", "button", "status" ]
  static values = { url: String }

  connect() {
    // A Turbo cache snapshot or a reconnect can already contain the controls; data-action rebinds them.
    // A snapshot taken mid-upload has a disabled button and a stale status, so reset both.
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      this.showStatus("")
      return
    }

    const textarea = this.textarea
    if (!textarea) return

    textarea.insertAdjacentElement("beforebegin", this.buildControls())
  }

  get textarea() {
    return this.element.querySelector("textarea")
  }

  buildControls() {
    const controls = document.createElement("div")
    controls.className = "flex flex-wrap items-center gap-2 mb-2"
    // No name attributes, so these inputs are never submitted with the post form.
    controls.innerHTML = `
      <input type="file" accept="${IMAGE_TYPES.join(",")}" class="text-sm"
        aria-label="Image file" data-html-image-insert-target="file">
      <input type="text" placeholder="Caption" class="input-field text-sm"
        aria-label="Image caption" data-html-image-insert-target="caption"
        data-action="keydown.enter->html-image-insert#insert">
      <button type="button" class="button button--size-sm button--style-outline"
        data-html-image-insert-target="button" data-action="html-image-insert#insert">Insert image</button>
      <span class="text-sm" role="status" aria-live="polite" data-html-image-insert-target="status"></span>
    `
    return controls
  }

  async insert(event) {
    event.preventDefault()
    if (this.buttonTarget.disabled) return

    const file = this.fileTarget.files[0]
    if (!file) return this.showError("Choose an image file first.")
    if (!IMAGE_TYPES.includes(file.type)) return this.showError("The file must be a PNG, JPEG, WebP or GIF image.")

    this.buttonTarget.disabled = true
    this.showStatus("Uploading…")
    try {
      const [ attachment, size ] = await Promise.all([ this.upload(file), measureImage(file) ])
      this.insertTag(this.attachmentTag(file, attachment, size, this.captionTarget.value.trim()))
      this.fileTarget.value = ""
      this.captionTarget.value = ""
      this.showStatus("Image inserted.")
    } catch (error) {
      this.showError(error.message || "Upload failed.")
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  async upload(file) {
    const form = new FormData()
    form.append("Content-Type", file.type)
    form.append("file", file)
    form.append("filename", file.name)
    form.append("key", `tmp/${new Date().toISOString().slice(0, 10)}/${Date.now()}-${file.name}`)

    let response
    try {
      response = await fetch(this.urlValue, {
        method: "POST",
        body: form,
        credentials: "same-origin",
        headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || "", Accept: "application/json" }
      })
    } catch {
      throw new Error("Upload failed: network error.")
    }
    // A redirect means the session expired (login page) or access was denied.
    if (response.status !== 200 || response.redirected) throw new Error(`Upload failed (HTTP ${response.status}).`)

    const json = await response.json().catch(() => ({}))
    if (!json.sgid || !json.url) throw new Error("Upload failed: no attachment id or URL returned.")
    return json
  }

  // Same attributes Trix stores (url/href keep the hidden Trix editor's preview working), in a similar order.
  attachmentTag(file, { sgid, url, href }, size, caption) {
    const attributes = { sgid, "content-type": file.type, filename: file.name, filesize: file.size }
    if (size) Object.assign(attributes, { width: size.width, height: size.height })
    Object.assign(attributes, { url, href: href || url })
    if (caption) attributes.caption = caption
    attributes.presentation = "gallery"

    const html = Object.entries(attributes).map(([ name, value ]) => `${name}="${escapeAttribute(value)}"`).join(" ")
    return `<action-text-attachment ${html}></action-text-attachment>`
  }

  // Replaces the selection (or inserts at the caret) with the tag on its own line.
  insertTag(tag) {
    const textarea = this.textarea
    const { selectionStart: start, selectionEnd: end, value } = textarea
    const before = start === 0 || value[start - 1] === "\n" ? "" : "\n"
    const after = value[end] === "\n" ? "" : "\n"

    textarea.focus()
    textarea.setRangeText(`${before}${tag}${after}`, start, end, "end")
    textarea.dispatchEvent(new Event("input", { bubbles: true }))
  }

  showStatus(message) {
    this.statusTarget.textContent = message
    this.statusTarget.classList.remove("text-red-700")
  }

  showError(message) {
    this.statusTarget.textContent = message
    this.statusTarget.classList.add("text-red-700")
  }
}

window.Stimulus?.register("html-image-insert", HtmlImageInsertController)
