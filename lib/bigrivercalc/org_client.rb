# frozen_string_literal: true

require "aws-sdk-organizations"

module Bigrivercalc
  OUInfo = Struct.new(:id, :name, keyword_init: true)

  class OrgClient
    def initialize
      @client = Aws::Organizations::Client.new
    end

    def root_id
      @client.list_roots.roots.first.id
    end

    # Returns an array of OUInfo for immediate child OUs of the given parent.
    def list_ous(parent_id)
      ous = []
      @client.list_organizational_units_for_parent(parent_id: parent_id).each_page do |page|
        page.organizational_units.each do |ou|
          ous << OUInfo.new(id: ou.id, name: ou.name)
        end
      end
      ous
    end

    # Returns an array of account ID strings for the given OU.
    def list_account_ids(ou_id)
      account_ids = []
      @client.list_accounts_for_parent(parent_id: ou_id).each_page do |page|
        page.accounts.each do |account|
          account_ids << account.id if account.status == "ACTIVE"
        end
      end
      account_ids
    end
  end
end
