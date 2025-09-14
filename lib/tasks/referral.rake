namespace :referral do
  desc "Generate referral tokens for existing users"
  task generate_tokens: :environment do
    users_without_token = User.where(referral_token: nil)
    
    puts "Generating referral tokens for #{users_without_token.count} users..."
    
    users_without_token.find_each do |user|
      user.send(:generate_referral_token)
      user.save!
      print "."
    end
    
    puts "\nCompleted! All users now have referral tokens."
  end
end