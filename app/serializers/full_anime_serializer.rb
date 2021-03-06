class FullAnimeSerializer < AnimeSerializer
  embed :ids, include: true

  attributes :alternate_title,
             :cover_image,
             :cover_image_top_offset,
             :screencaps,
             :languages,
             :community_ratings,
             :youtube_video_id,
             :bayesian_rating,
             :pending_edits,
             :has_reviewed

  has_many :featured_quotes, root: :quotes
  has_many :trending_reviews, root: :reviews
  has_many :featured_castings, root: :castings
  has_many :producers, embed_key: :slug
  has_many :franchises, include: false
  has_many :episodes
  has_one :library_entry

  def alternate_title
    object.alternate_title(scope.try(:title_language_preference) || 'canonical')
  end

  def has_reviewed
    scope && Review.exists?(user_id: scope.id, anime_id: object.id)
  end

  def library_entry
    scope && LibraryEntry.where(user_id: scope.id, anime_id: object.id).first
  end

  def cover_image
    object.cover_image_file_name ? object.cover_image.url(:thumb) : nil
  end

  def cover_image_top_offset
    object.cover_image_top_offset || 0
  end

  def screencaps
    object.gallery_images.limit(4).map {|g| g.image.url(:thumb) }
  end

  def languages
    object.castings.where(role: "Voice Actor").select("DISTINCT(language)").map(&:language).sort
  end

  def featured_quotes
    object.quotes.includes(:user).order('positive_votes DESC').limit(4)
  end

  def trending_reviews
    object.reviews.includes(:user).order("wilson_score DESC").limit(4)
  end

  def featured_castings
    object.castings.where(featured: true).includes(:person, :character).sort_by {|x| x.order || 100 }
  end

  def pending_edits
    scope && Version.pending.where(user: scope, item: object).count
  end
end
