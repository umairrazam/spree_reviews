class Spree::Review < ActiveRecord::Base
  belongs_to :product, touch: true
  belongs_to :user, class_name: Spree.user_class.to_s
  has_many   :feedback_reviews

  after_save :recalculate_product_rating
  after_destroy :recalculate_product_rating

  validates :rating, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5,
    message: Spree.t(:you_must_enter_value_for_rating)
  }
  default_scope { order('spree_reviews.created_at DESC') }

  scope :localized, ->(lc) { where('spree_reviews.locale = ?', lc) }
  scope :most_recent_first, -> { order('spree_reviews.created_at DESC') }
  scope :oldest_first, -> { reorder('spree_reviews.created_at ASC') }
  scope :preview, -> { limit(Spree::Reviews::Config[:preview_size]).oldest_first }
  scope :approved, -> { where(approved: true) }
  scope :not_approved, -> { where(approved: false) }
  scope :default_approval_filter, -> { Spree::Reviews::Config[:include_unapproved_reviews] ? all : approved }
  scope :rating_with_five, -> { where(rating: '5').count }
  scope :rating_with_four, -> { where(rating: '4').count }
  scope :rating_with_three, -> { where(rating: '3').count }
  scope :rating_with_two, -> { where(rating: '2').count }
  scope :rating_with_one, -> { where(rating: '1').count }

  enum product_worth: %i[yes no dont_know], _prefix: :product_worth
  enum product_recommend: %i[yes no dont_know], _prefix: :product_recommend
  enum vendor_recommend: %i[yes no dont_know], _prefix: :vendor_recommend

  def feedback_stars
    return 0 if feedback_reviews.size <= 0

    ((feedback_reviews.sum(:rating) / feedback_reviews.size) + 0.5).floor
  end

  def update_product
    product.touch
  end  

  def recalculate_product_rating
    product.recalculate_rating if product.present?
  end
end
