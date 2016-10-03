# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "google/cloud/errors"

module Google
  module Cloud
    module Pubsub
      ##
      # # Policy
      #
      # Represents a Cloud IAM Policy for the Pub/Sub service.
      #
      # A common pattern for updating a resource's metadata, such as its Policy,
      # is to read the current data from the service, update the data locally,
      # and then send the modified data for writing. This pattern may result in
      # a conflict if two or more processes attempt the sequence simultaneously.
      # IAM solves this problem with the {Google::Cloud::Pubsub::Policy#etag}
      # property, which is used to verify whether the policy has changed since
      # the last request. When you make a request to with an `etag` value, Cloud
      # IAM compares the `etag` value in the request with the existing `etag`
      # value associated with the policy. It writes the policy only if the
      # `etag` values match.
      #
      # When you update a policy, first read the policy (and its current `etag`)
      # from the service, then modify the policy locally, and then write the
      # modified policy to the service. See
      # {Google::Cloud::Pubsub::Topic#policy} and
      # {Google::Cloud::Pubsub::Topic#policy=}.
      #
      # @see https://cloud.google.com/iam/docs/managing-policies Managing
      #   policies
      # @see https://cloud.google.com/pubsub/docs/reference/rpc/google.iam.v1#iampolicy
      #   google.iam.v1.IAMPolicy
      #
      # @attr [String] etag Used to verify whether the policy has changed since
      #   the last request. The policy will be written only if the `etag` values
      #   match.
      # @attr [Hash{String => Array<String>}] roles The bindings that associate
      #   roles with an array of members. See [Understanding
      #   Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
      #   listing of primitive and curated roles.
      #   See [Binding](https://cloud.google.com/pubsub/docs/reference/rpc/google.iam.v1#binding)
      #   for a listing of values and patterns for members.
      #
      # @example
      #   require "google/cloud"
      #
      #   gcloud = Google::Cloud.new
      #   pubsub = gcloud.pubsub
      #   topic = pubsub.topic "my-topic"
      #
      #   policy = topic.policy # API call
      #
      #   policy.remove "roles/owner", "user:owner@example.com" # Local call
      #   policy.add "roles/owner", "user:newowner@example.com" # Local call
      #   policy.roles["roles/viewer"] = ["allUsers"] # Local call
      #
      #   topic.policy = policy # API call
      #
      class Policy
        attr_reader :etag, :roles

        ##
        # @private Creates a Policy object.
        def initialize etag, roles
          @etag = etag
          @roles = roles
        end

        ##
        # Convenience method for adding a member to a binding on this policy.
        # See [Understanding
        # Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
        # listing of primitive and curated roles.
        # See [Binding](https://cloud.google.com/pubsub/docs/reference/rpc/google.iam.v1#binding)
        # for a listing of values and patterns for members.
        #
        # @param [String] role_name A Cloud IAM role, such as
        #   `"roles/pubsub.admin"`.
        # @param [String] member A Cloud IAM identity, such as
        #   `"user:owner@example.com"`.
        #
        # @example
        #   require "google/cloud"
        #
        #   gcloud = Google::Cloud.new
        #   pubsub = gcloud.pubsub
        #   topic = pubsub.topic "my-topic"
        #
        #   policy = topic.policy # API call
        #
        #   policy.add "roles/owner", "user:newowner@example.com" # Local call
        #
        #   topic.policy = policy # API call
        #
        def add role_name, member
          role(role_name) << member
        end

        ##
        # Convenience method for removing a member from a binding on this
        # policy. See [Understanding
        # Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
        # listing of primitive and curated roles. See
        # [Binding](https://cloud.google.com/pubsub/docs/reference/rpc/google.iam.v1#binding)
        # for a listing of values and patterns for members.
        #
        # @param [String] role_name A Cloud IAM role, such as
        #   `"roles/pubsub.admin"`.
        # @param [String] member A Cloud IAM identity, such as
        #   `"user:owner@example.com"`.
        #
        # @example
        #   require "google/cloud"
        #
        #   gcloud = Google::Cloud.new
        #   pubsub = gcloud.pubsub
        #   topic = pubsub.topic "my-topic"
        #
        #   policy = topic.policy # API call
        #
        #   policy.remove "roles/owner", "user:owner@example.com" # Local call
        #
        #   topic.policy = policy # API call
        #
        def remove role_name, member
          role(role_name).delete member
        end

        ##
        # Convenience method returning the array of members bound to a role in
        # this policy, or an empty array if no value is present for the role in
        # {#roles}. See [Understanding
        # Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
        # listing of primitive and curated roles. See
        # [Binding](https://cloud.google.com/pubsub/docs/reference/rpc/google.iam.v1#binding)
        # for a listing of values and patterns for members.
        #
        # @return [Array<String>] The members strings, or an empty array.
        #
        # @example
        #   require "google/cloud"
        #
        #   gcloud = Google::Cloud.new
        #   pubsub = gcloud.pubsub
        #   topic = pubsub.topic "my-topic"
        #
        #   policy = topic.policy
        #
        #   policy.role("roles/viewer") << "user:viewer@example.com"
        #
        def role role_name
          roles[role_name] ||= []
        end

        ##
        # Returns a deep copy of the policy.
        #
        # @return [Policy]
        #
        def deep_dup
          dup.tap do |p|
            roles_dup = p.roles.each_with_object({}) do |(k, v), memo|
              memo[k] = v.dup rescue value
            end
            p.instance_variable_set "@roles", roles_dup
          end
        end

        ##
        # @private Convert the Policy to a Google::Iam::V1::Policy object.
        def to_grpc
          Google::Iam::V1::Policy.new(
            etag: etag,
            bindings: roles.keys.map do |role_name|
              next if roles[role_name].empty?
              Google::Iam::V1::Binding.new(
                role: role_name,
                members: roles[role_name]
              )
            end
          )
        end

        ##
        # @private New Policy from a Google::Iam::V1::Policy object.
        def self.from_grpc grpc
          roles = grpc.bindings.each_with_object({}) do |binding, memo|
            memo[binding.role] = binding.members.to_a
          end
          new grpc.etag, roles
        end
      end
    end
  end
end