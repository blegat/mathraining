#encoding: utf-8
class ActiveStorage::BlobsController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob
  
  def show
    # The only difference with the default BlobsController is this "unless Rails.env.test?".
    # Indeed we had some random failures in our tests. They were due to the fact that two tests
    # were creating, one after the other, a Blob with the same id and the same file name (but
    # with different keys). Then their limited lifetime urls were the same (because they depend
    # only on the id and the filename) but their service urls were different. By removing the
    # following line in test environment we ensure that the service url is always recomputed.
    # See https://github.com/rails/rails/issues/34989 for more information
    expires_in ActiveStorage::Blob.service.url_expires_in unless Rails.env.test?
    redirect_to @blob.service_url(disposition: params[:disposition])
  end
end
