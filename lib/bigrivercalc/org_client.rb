# frozen_string_literal: true

require "aws-sdk-organizations"

module Bigrivercalc
  class OrgClient
    def initialize
      @client = Aws::Organizations::Client.new
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
