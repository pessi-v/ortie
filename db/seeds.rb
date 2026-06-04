# Seeds a development "world" for Ortie: a known primary login plus ~30 other
# people, wired so all five discovery sections (New / Liked / Passed / Likes you /
# Matches) and messaging have content.
#
# Additive + idempotent: keyed on @ortie.test emails, so re-running won't
# duplicate and won't touch your own test accounts. Run with: bin/rails db:seed
#
# Photos: a real AI-generated face per person, attached and marked approved
# (bypassing the sidecar). Faces come from the offline pool in db/seeds/faces/
# (exported from thispersondoesnotexist.com — no network needed). Set
# SEED_PHOTOS=0 to skip them and fall back to gradient-initial avatars.

if Rails.env.production? && ENV["FORCE_SEED"].blank?
  abort "Refusing to seed in production. Set FORCE_SEED=1 to override."
end

FACE_POOL = ENV["SEED_PHOTOS"] == "0" ? [] : Dir[Rails.root.join("db/seeds/faces/*.jpg")].sort
warn "No face pool found in db/seeds/faces — using gradient avatars." if FACE_POOL.empty? && ENV["SEED_PHOTOS"] != "0"

# Ensure the user has one approved photo; attach a face from the pool unless it
# already has an image (so re-runs don't re-attach) or there's no pool.
def ensure_photo(user, face)
  photo = user.photos.first || user.photos.create!(position: 1, moderation_status: :approved)
  photo.update!(moderation_status: :approved) unless photo.approved?
  return if photo.image.attached? || face.nil?

  photo.image.attach(io: File.open(face), filename: File.basename(face), content_type: "image/jpeg")
end

PASSWORD = "password"
BERLIN = { lat: 52.52, lng: 13.405 }
BIOS = [
  "Cyclist, sourdough enthusiast, terrible at chess.",
  "Into long walks and short films.",
  "Plants, postal stamps, and post-punk.",
  "Will trade book recommendations for coffee.",
  "Climbing on weekends, cooking on weeknights.",
  "Quietly competitive at board games.",
  "Looking for someone to share quiet mornings with.",
  "Museum wanderer and amateur birdwatcher.",
  "Synths, succulents, and spicy food.",
  "Here for the dog photos, staying for the conversation."
].freeze

# name, gender, age, message_preference, donor, distance bucket (:near/:mid/:far)
PEOPLE = [
  ["Mara", :woman, 29, :no_preference, false, :near],
  ["Theo", :man, 31, :prefers_intro, true, :near],
  ["Iris", :nonbinary, 27, :prefers_to_write_first, false, :near],
  ["Bruno", :man, 34, :no_preference, false, :near],
  ["Lena", :woman, 26, :prefers_intro, false, :mid],
  ["Idris", :man, 33, :no_preference, true, :near],
  ["Nora", :nonbinary, 30, :prefers_to_write_first, false, :near],
  ["Sven", :man, 38, :no_preference, false, :mid],
  ["Yara", :woman, 28, :prefers_intro, false, :near],
  ["Cem", :man, 32, :no_preference, false, :near],
  ["Pia", :nonbinary, 25, :prefers_to_write_first, true, :near],
  ["Jonas", :man, 36, :no_preference, false, :mid],
  ["Suki", :woman, 29, :prefers_intro, false, :near],
  ["Aleks", :nonbinary, 31, :no_preference, false, :near],
  ["Romy", :woman, 27, :prefers_to_write_first, false, :near],
  ["Tariq", :man, 35, :no_preference, true, :mid],
  ["Vesna", :woman, 33, :prefers_intro, false, :near],
  ["Milo", :man, 28, :no_preference, false, :near],
  ["Fadi", :man, 30, :prefers_to_write_first, false, :near],
  ["Greta", :woman, 41, :no_preference, false, :mid],
  ["Hugo", :man, 37, :prefers_intro, false, :near],
  ["Noa", :nonbinary, 26, :no_preference, false, :near],
  ["Bex", :woman, 24, :prefers_to_write_first, false, :near],
  ["Otto", :man, 44, :no_preference, true, :mid],
  ["Kira", :woman, 32, :prefers_intro, false, :near],
  ["Dario", :man, 29, :no_preference, false, :near],
  ["Lux", :nonbinary, 34, :prefers_to_write_first, false, :near],
  ["Emin", :man, 39, :no_preference, false, :mid],
  ["Saskia", :woman, 52, :no_preference, false, :near],   # outside Ace's age range
  ["Wim", :man, 33, :no_preference, false, :far]          # outside Ace's distance
].freeze

def coords_for(bucket, index)
  case bucket
  when :near then { lat: BERLIN[:lat] + ((index % 7) - 3) * 0.01, lng: BERLIN[:lng] + ((index % 5) - 2) * 0.01 }
  when :mid  then { lat: BERLIN[:lat] + 0.3, lng: BERLIN[:lng] + 0.2 }       # ~35 km
  when :far  then { lat: 48.137, lng: 11.575 }                              # Munich, ~500 km
  end
end

def upsert_person(email:, name:, gender:, age:, message_preference:, donor:, coords:, face: nil,
                  sought: [], age_min: 18, age_max: 99, max_distance_km: 50)
  user = User.find_or_create_by!(email: email) do |u|
    u.password = PASSWORD
    u.donor = donor
    u.message_preference = message_preference
    u.latitude = coords[:lat]
    u.longitude = coords[:lng]
    u.location_label = "Berlin"
    u.last_active_at = rand(0..120).hours.ago
  end

  user.create_profile!(display_name: name, birthdate: age.years.ago.to_date,
                       gender: gender, bio: BIOS.sample) if user.profile.nil?
  user.create_user_preference!(age_min: age_min, age_max: age_max,
                               max_distance_km: max_distance_km, sought_genders: sought) if user.user_preference.nil?
  ensure_photo(user, face)
  user
end

# Faces assigned deterministically, cycling the pool if there are fewer than people.
def face_for(index)
  return nil if FACE_POOL.empty?

  FACE_POOL[index % FACE_POOL.size]
end

# ---- primary login ---------------------------------------------------------
ace = upsert_person(
  email: "ace@ortie.test", name: "Ace", gender: :woman, age: 30,
  message_preference: :prefers_intro, donor: true, coords: BERLIN, face: face_for(0),
  sought: [Profile.genders[:man], Profile.genders[:nonbinary]],
  age_min: 25, age_max: 45, max_distance_km: 100
)

# ---- everyone else ---------------------------------------------------------
people = PEOPLE.each_with_index.map do |(name, gender, age, pref, donor, bucket), i|
  upsert_person(
    email: "#{name.downcase}@ortie.test", name: name, gender: gender, age: age,
    message_preference: pref, donor: donor, coords: coords_for(bucket, i), face: face_for(i + 1),
    sought: Profile.genders.values, age_min: 21, age_max: 60, max_distance_km: 100
  )
end

# ---- weave the graph around Ace (idempotent via RecordLike upserts) ---------
likes_you = people[0..4]    # liked Ace, awaiting his move
matches   = people[5..8]    # mutual → matches
liked     = people[9..14]   # Ace liked, no reciprocal yet
passed    = people[15..18]  # Ace passed
# people[19..] stay as fresh New-profile candidates

intros = ["Hi! Your bio made me smile.", nil, "Coffee sometime?", nil, "We have the same taste in films."]
likes_you.each_with_index do |person, i|
  RecordLike.new(actor: person, target: ace, kind: :like, intro_note: intros[i]).call
end

matches.each do |person|
  RecordLike.new(actor: person, target: ace, kind: :like).call # they liked first
  RecordLike.new(actor: ace, target: person, kind: :like).call # Ace likes back → match
end

liked.each { |person| RecordLike.new(actor: ace, target: person, kind: :like).call }
passed.each { |person| RecordLike.new(actor: ace, target: person, kind: :pass).call }

# ---- a couple of conversations with messages -------------------------------
SCRIPT = [
  "hey! nice to match :)",
  "hey yourself — how's your week going?",
  "good! survived a long Monday. you?",
  "same. want to grab coffee this weekend?"
].freeze

matches.first(2).each do |person|
  conversation = Match.between(ace, person).first.conversation
  next if conversation.messages.any?

  SCRIPT.each_with_index do |body, i|
    sender = i.even? ? person : ace
    conversation.messages.create!(sender: sender, body: body)
  end
  last = conversation.messages.order(:created_at).last
  conversation.update!(last_message_at: last.created_at)
  # leave the latest message unread for whoever didn't send it
  recipient = conversation.conversation_participants.where.not(user_id: last.sender_id).first
  recipient&.update!(unread_count: 1)
end

# ---- a sample report -------------------------------------------------------
Report.find_or_create_by!(reporter: people[19], reported: people[20]) do |r|
  r.reason = :spam
  r.note = "Looks like a bot account."
end

puts "Seeded. Primary login: ace@ortie.test / #{PASSWORD}"
puts "Users: #{User.count} | Likes: #{Like.count} | Matches: #{Match.confirmed.count} | Messages: #{Message.count} | Reports: #{Report.count}"
puts "Ace — Likes you: #{ace.reload.pending_likes_count} | Matches: #{Match.confirmed.for_user(ace).count}"
