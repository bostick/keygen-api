# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ArtifactsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[index show]
    before_action :authenticate_with_token, only: %i[index show]
    before_action :set_release

    def index
      artifacts = apply_pagination(apply_scopes(policy_scope(release.artifacts)))
      authorize artifacts

      render jsonapi: artifacts
    end

    def show
      artifact = FindByAliasService.call(scope: release.artifacts, identifier: params[:id], aliases: :key)
      authorize artifact

      # FIXME(ezekg) This should support multiple artifacts
      download = ReleaseDownloadService.call(
        account: current_account,
        release: artifact.release,
        ttl: artifact_query[:ttl],
      )

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: download.artifact,
      )

      render jsonapi: download.artifact, status: :see_other, location: download.redirect_url
    rescue ReleaseDownloadService::InvalidTTLError => e
      render_bad_request detail: e.message, source: { parameter: :ttl }
    rescue ReleaseDownloadService::InvalidArtifactError => e
      render_not_found detail: e.message
    rescue ReleaseDownloadService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = FindByAliasService.call(scope: scoped_releases, identifier: params[:release_id], aliases: :filename)

      Current.resource = release
    end

    typed_query do
      on :show do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          query :ttl, type: :integer, coerce: true, optional: true
        end
      end
    end
  end
end
