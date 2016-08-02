# encoding: UTF-8
# frozen_string_literal: true

# Source image model.
class SrcImage < ActiveRecord::Base
  include HasImageConcern
  include IdHashConcern

  belongs_to :user
  has_one :src_thumb
  has_many :gend_images
  has_and_belongs_to_many :src_sets, join_table: :src_images_src_sets

  before_validation :add_url_scheme

  validate :image_if_not_url

  after_commit :create_jobs, on: :create

  attr_accessor :image_url

  def image_if_not_url
    if url.blank? && image.blank?
      errors.add :image, 'is required if url is not set.'.freeze
    end
  end

  def load_from_url
    return unless url
    self.image = MemeCaptainWeb::ImgUrlComposer.new.load(url)
  end

  def create_jobs
    SrcImageProcessJob.new(id).delay(queue: queue).perform
  end

  def self.for_user(user, query, page)
    if user.try(:is_admin)
      without_image.includes(:src_thumb).name_matches(query)
                   .most_used.page(page)
    else
      without_image.includes(:src_thumb).name_matches(query)
                   .publick.active.finished.most_used.page(page)
    end
  end

  scope :active, -> { where is_deleted: false }

  scope :owned_by, ->(user) { where user_id: user.id }

  scope :most_recent, lambda { |limit = 1|
    order(:updated_at).reverse_order.limit(limit)
  }

  scope :publick, -> { where private: false }

  scope :name_matches, MemeCaptainWeb::TextMatchLambda.new(self, :name).lambder

  def self.searchable_columns
    [:name]
  end

  scope :most_used, lambda { |limit = 1|
    order(:gend_images_count).reverse_order.limit(limit)
  }

  scope :finished, -> { where work_in_progress: false }

  private

  def add_url_scheme
    return true if url.blank?
    return true if url.start_with?(
      'http://'.freeze, 'https://'.freeze, 'data:'.freeze
    )
    self.url = "http://#{url}"
    true
  end

  def queue
    url? ? :src_image_process_url : :src_image_process
  end
end
