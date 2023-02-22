# frozen_string_literal: true

FactoryBot.define do
  factory :machine do
    initialize_with { new(**attributes.reject { NIL_ENVIRONMENT == _2 }) }

    fingerprint { SecureRandom.hex(12).upcase.scan(/.{2}/).join ":" }
    name        { Faker::Company.buzzword }

    account     { nil }
    environment { NIL_ENVIRONMENT }
    license     { build(:license, account:, environment:) }

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      after :create do |machine|
        machine.environment = nil
        machine.save!(validate: false)
      end
    end

    trait :global do
      in_nil_environment
    end
  end
end
