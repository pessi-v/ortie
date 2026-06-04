import { Controller } from "@hotwired/stimulus"

// One-profile-at-a-time browsing. Horizontal swipe is native (CSS scroll-snap);
// this adds desktop arrow buttons + keyboard, and reveals an empty state once
// every slide has been acted on (slides are removed by the like/pass streams).
export default class extends Controller {
  static targets = ["track", "empty", "controls"]

  connect() {
    this.onKey = (e) => {
      if (e.key === "ArrowLeft") this.prev()
      else if (e.key === "ArrowRight") this.next()
    }
    window.addEventListener("keydown", this.onKey)
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.trackTarget, { childList: true })
    this.refresh()
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKey)
    this.observer?.disconnect()
  }

  next() { this.scrollByCard(1) }
  prev() { this.scrollByCard(-1) }

  scrollByCard(direction) {
    const slide = this.trackTarget.querySelector(".carousel-slide")
    const width = slide ? slide.getBoundingClientRect().width : this.trackTarget.clientWidth
    this.trackTarget.scrollBy({ left: direction * width, behavior: "smooth" })
  }

  refresh() {
    const empty = this.trackTarget.querySelectorAll(".carousel-slide").length === 0
    this.trackTarget.hidden = empty
    if (this.hasEmptyTarget) this.emptyTarget.hidden = !empty
    if (this.hasControlsTarget) this.controlsTarget.hidden = empty
  }
}
