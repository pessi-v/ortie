module ApplicationHelper
  def input_class
    "w-full rounded-lg border border-gray-300 px-3 py-2"
  end

  def button_class
    "rounded-lg bg-rose-600 text-white px-4 py-2 text-sm font-medium hover:bg-rose-700 cursor-pointer"
  end

  def nav_link_class(active)
    base = "px-2 py-1 rounded-md hover:bg-gray-100"
    active ? "#{base} text-rose-600 font-medium" : "#{base} text-gray-600"
  end

  MESSAGE_PREFERENCE_LABELS = {
    "no_preference"          => nil,
    "prefers_to_write_first" => "✍ prefers to write first",
    "prefers_intro"          => "✉ prefers to receive an intro"
  }.freeze

  def message_preference_label(user)
    MESSAGE_PREFERENCE_LABELS[user.message_preference]
  end

  PHOTO_STATUS_PILL = {
    "pending"  => "bg-gray-200 text-gray-700",
    "approved" => "bg-green-100 text-green-800",
    "review"   => "bg-amber-100 text-amber-800",
    "rejected" => "bg-rose-100 text-rose-800"
  }.freeze

  def photo_status_pill_class(photo)
    PHOTO_STATUS_PILL.fetch(photo.moderation_status, "bg-gray-200 text-gray-700")
  end

  # Minimal inline Lucide-style stroke icons (MIT) — no icon gem dependency.
  ICON_PATHS = {
    heart:  '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.29 1.51 4.04 3 5.5l7 7Z"/>',
    x:      '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    flag:   '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/>',
    pencil: '<path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
    undo:   '<path d="M3 7v6h6"/><path d="M21 17a9 9 0 0 0-9-9 9 9 0 0 0-6 2.3L3 13"/>'
  }.freeze

  def lucide(name)
    %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">#{ICON_PATHS.fetch(name.to_sym)}</svg>).html_safe
  end

  # The user's primary photo as an <img> (given variant), or a gradient-initial
  # placeholder when there's no usable photo. `classes` styles either result.
  def avatar_for(user, variant: :card, classes: "")
    photo = user.primary_photo
    if photo&.image&.attached?
      image_tag photo.image.variant(variant), class: "object-cover #{classes}", loading: "lazy"
    else
      initial = user.profile&.display_name.to_s.first
      content_tag :div, initial,
                  class: "bg-gradient-to-br from-rose-200 to-sky-200 flex items-center justify-center text-white font-semibold #{classes}"
    end
  end
end
