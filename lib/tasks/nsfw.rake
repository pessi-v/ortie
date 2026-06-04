namespace :photos do
  desc "Report NSFW moderation sidecar status"
  task nsfw_status: :environment do
    puts "NSFW moderation sidecar"
    puts "  NSFW_SERVICE_URL: #{NsfwDetector.base_url}"
    puts "  available?:       #{NsfwDetector.available?}"
    puts
    if NsfwDetector.available?
      puts "Sidecar is up — uploads and sign-ups are open and photos are classified."
    else
      puts "Sidecar is DOWN — sign-ups and photo uploads are paused until it's reachable."
      puts "Start it locally with:  cd nsfw_service && npm run fetch-model && PORT=3001 npm start"
      puts "(or `bin/dev`, which runs it). In prod it's a Kamal accessory; see nsfw_service/README.md."
    end
  end
end
