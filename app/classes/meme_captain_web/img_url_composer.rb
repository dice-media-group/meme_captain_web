module MemeCaptainWeb
  # Build composite images from urls.
  #
  # The urls passed in can be normal urls or multiple urls joined with
  # '[]' (horizotal join) and '|' (vertical join). The returned image data
  # will be a composite image built according to the joins in the url.
  #
  # Multiple horizontal and vertical combines can be done together.
  class ImgUrlComposer
    def initialize
      @url_getter = MemeCaptainWeb::UrlGetter.new
    end

    def load(url)
      case url
      when /\|/
        combine_vertical(url)
      when /\[\]/
        combine_horizontal(url)
      else
        @url_getter.get(url)
      end
    end

    private

    def combine_horizontal(url)
      images = url.split('[]').map do |u|
        Magick::ImageList.new.from_blob(load(u)).first
      end

      equalize_height(images)

      img_list = Magick::ImageList.new
      img_list.push(*images)

      img_list.append(false).to_blob
    end

    def equalize_height(images)
      min_height = images.map(&:rows).min

      images.select { |i| i.rows > min_height }.each do |i|
        i.resize_to_fit!(nil, min_height)
      end
    end

    def combine_vertical(url)
      images = url.split('|').map do |u|
        Magick::ImageList.new.from_blob(load(u)).first
      end

      equalize_width(images)

      img_list = Magick::ImageList.new
      img_list.push(*images)

      img_list.append(true).to_blob
    end

    def equalize_width(images)
      min_width = images.map(&:columns).min

      images.select { |i| i.columns > min_width }.each do |i|
        i.resize_to_fit!(min_width)
      end
    end
  end
end