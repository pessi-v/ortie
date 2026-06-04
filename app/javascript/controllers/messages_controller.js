import { Controller } from "@hotwired/stimulus"

// Aligns/colors message bubbles client-side (broadcasts render without a
// current user) and keeps the thread scrolled to the latest message.
export default class extends Controller {
  static values = { userId: Number }

  connect() {
    this.render()
    this.observer = new MutationObserver(() => this.render())
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  render() {
    this.element.querySelectorAll(".message").forEach((row) => {
      const mine = Number(row.dataset.senderId) === this.userIdValue
      const bubble = row.querySelector(".bubble")
      if (!bubble) return
      bubble.classList.toggle("bubble--mine", mine)
      bubble.classList.toggle("bubble--theirs", !mine)
    })
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
