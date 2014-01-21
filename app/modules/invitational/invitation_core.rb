module Invitational
  module InvitationCore
    extend ActiveSupport::Concern

    included do
      belongs_to :user, :class_name => Invitational.user_class
      belongs_to :invitable, :polymorphic => true

      validates :email,  :presence => true
      validates :role,  :presence => true
      validates :invitable,  :presence => true, :if => :standard_role?

      scope :uber_admin, lambda {
        where('invitable_id IS NULL AND role = "uberadmin"')
      }

      scope :for_email, lambda {|email|
        where('email = ?', email)
      }

      scope :pending_for, lambda {|email|
        where('email = ? AND user_id IS NULL', email)
      }

      scope :for_claim_hash, lambda {|claim_hash|
        where('claim_hash = ?', claim_hash)
      }

      scope :for_invitable, lambda {|type, id|
        where('invitable_type = ? AND invitable_id = ?', type, id)
      }

      scope :by_role, lambda {|role|
        role_id = Invitational::Role[role]
        where('role = ?', role_id)
      }

      scope :pending, lambda { where('user_id IS NULL') }
      scope :claimed, lambda { where('user_id IS NOT NULL') }
    end

    module ClassMethods

    end

    def standard_role?
      if role.is_a? Symbol
        role != :uberadmin
      else
        role.to_i >= 0
      end
    end

    def role
      super.to_sym
    end

    def role=(value)
      super(value.to_sym)
      role
    end

    def user= user
      if user.nil?
        self.date_accepted = nil
      else
        self.date_accepted = DateTime.now
      end

      super user
    end

    def save(*)
      if id.nil?
        self.date_sent = DateTime.now
        self.claim_hash = Digest::SHA1.hexdigest(email + date_sent.to_s)
      end

      super
    end

    def role_title
      if uber_admin?
        "Uber Admin"
      else
        Invitational.roles[role].display_name
      end
    end

    def uber_admin?
      invitable.nil? == true && role == -1
    end

    def claimed?
      user.nil? == false
    end

    def unclaimed?
      !claimed?
    end

  end
end
