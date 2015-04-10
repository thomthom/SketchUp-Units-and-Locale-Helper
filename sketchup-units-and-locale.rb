module Example

  # Helper module for dealing with locale data and unit conversions.
  module Locale

    extend self

    # Model Units set to Centimeters with precision 0,000:
    #
    #   Locale.string_to_unit( '123.345cm' )
    #   => "123,345cm"
    #
    #   Locale.string_to_unit( '123.345cm2' )
    #   => "123,345 Centimeters ²""
    #
    #   Locale.string_to_unit( '123.345cm3' )
    #   => "123,345 Centimeters ³""
    #
    #   Locale.string_to_unit( '123.345cm³' )
    #   => "123,345 Centimeters ³""
    #
    #   Locale.string_to_unit( '123 456.345cm3' )
    #   => "123456,345 Centimeters ³""
    #
    # @param [String] string
    #
    # @return [Volume] if unit marker ends with 3. ( +'123.cm3'+ )
    # @return [Area] if unit marker ends with 2. ( +'123.cm2'+ )
    # @return [Length] if there is no dimension marker.
    def self.string_to_unit( string )
      # Make string easier to parse by normalising characters.
      data = string.gsub('²','2').gsub('³','3').gsub(/\s+/,'')
      # Parse unit components.
      # (!) Add support for km, inch, foot, yard, mile
      match = data.match( /^([0-9]+([.,][0-9]*)?)((['"mc]+)([23]?))?$/ )
      #p match # <debug/>
      unless match
        raise ArgumentError, "Cannot convert #{string.inspect} to unit"
      end
      # Extract parsed data.
      value = match[1].tr(',','.').to_f
      unit_full = match[3]
      unit = match[4]
      dimmension = match[5].to_i
      # <debug>
      #puts "      Value: #{value}"
      #puts "Unit (Full): #{unit_full}"
      #puts "       Unit: #{unit}"
      #puts " Dimension: #{dimension}"
      # </debug>
      # Convert into appropriate class.
      case dimmension
      when 0
        @@decimal_separator ||= self.decimal_separator()
        match[0].tr('.', @@decimal_separator).to_l
      when 2
        Area.send( unit_full.intern, value )
      when 3
        Volume.send( unit_full.intern, value )
      else
        raise ArgumentError, 'Invalid unit format #{unit_full.inspect}'
      end
    end

    # Dirty hack extracting guessing the decimal separator of the current
    # locale. Assumes that only . and , are possible values.
    #
    # @return [String]
    def decimal_separator
      '1.0'.to_l
      return '.'
    rescue ArgumentError
      return ','
    end

    # Dirty hack guessing the list separator of the current locale.
    # Assumes that only , and : are possible values.
    #
    # @return [String]
    def list_separator
      ( decimal_separator == '.' ) ? ',' : ';'
    end

    # Formats the given float to a string with the user's locale decimal
    # delimiter and with the precision given in the model's option for lengths.
    #
    # @param [Float] string
    # @param [Boolean] trim Trims trailing zeros. (For area and volume in SketchUp.)
    # @param [Sketchup::Model, Integer] model SketchUp model to use model settings
    #   or fixed precision if an integer is given.
    #
    # @return [String]
    def format_float( float, trim = false, model = Sketchup.active_model )
      # For areas and volumes, SketchUp drops the trailing zeros after the
      # decimal separator.
      @@decimal_separator ||= decimal_separator()
      if model.is_a?( Sketchup::Model )
        precision = model.options['UnitsOptions']['LengthPrecision']
      else
        precision = model.to_i
      end
      num = sprintf( "%.#{precision}f", float )
      num.sub!( /(^[0-9]+([.,]?[1-9]+)?)([.,]?[0]*)/, '\1' ) if trim # trailing 0
      num.tr!( '.', @@decimal_separator )
      num
    end

  end # module Locale


  # Model Units set to Meters with precision 0,0:
  #
  #   a1 = Area.m2( 30 )
  #   => "30 Meters ²"
  #
  #   a2 = Area.cm2( 2000 )
  #   => "0,2 Meters ²"
  #
  #   a3 = a1 + a2
  #   => "30,2 Meters ²"
  #
  #   Area.m2( 30 ) * 2
  #   => "60 Meters ²"
  #
  #   Area.m2( 30 ) / 2
  #   => "15 Meters ²"
  #
  #   length = Area.m2( 9 ).squared
  #   => "3,0m"
  #
  #   Area.new( 10000000 )
  #   => "6451,6 Meters ²"
  #
  #   Area.inch2( 10000000 )
  #   => "6451,6 Meters ²"
  #
  #   volume = Area.m2(9) * 3.m
  #   => "27 Meters ³"
  #
  #   length = Area.m2(9) / 2.m
  #   => "4,5m"
  class Area

    include Comparable
    include Locale

    def initialize( number )
      @area = number.to_f
    end


    # @param [#to_f] number
    #
    # @return [Area]
    def +( number )
      self.class.new( @area + number.to_f )
    end

    # @param [#to_f] number
    #
    # @return [Area]
    def -( number )
      self.class.new( @area - number.to_f )
    end

    # @param [Numeric] number
    #
    # @return [Volume] if multiplied by a +Length+.
    # @return [Area] if multiplied by a +Numeric+ object.
    def *( number )
      if number.is_a?( Length )
        Volume.new( @area * number )
      else
        self.class.new( @area * number )
      end
    end

    # @param [Numeric] number
    #
    # @return [Length] if divided by a +Length+.
    # @return [Area] if divided by a +Numeric+ object.
    def /( number )
      if number.is_a?( Length )
        ( @area / number ).to_l
      else
        self.class.new( @area / number )
      end
    end


    # @param [#to_f] number
    #
    # @return [Area]
    def <=>( area )
      @area <=> area.to_f
    end


    # @return [Length]
    def squared
      Math.sqrt( @area ).to_l
    end


    # @param [Numeric] number
    #
    # @return [Area]
    def self.mm2( number )
      ratio = 1.mm * 1.mm
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Area]
    def self.cm2( number )
      ratio = 1.cm * 1.cm
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Area]
    def self.m2( number )
      ratio = 1.m * 1.m
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Area]
    def self.km2( number )
      ratio = 1.km * 1.km
      self.new( number * ratio )
    end


    # @param [Numeric] number
    #
    # @return [Area]
    def self.inch2( number )
      ratio = 1.inch * 1.inch
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Area]
    def self.feet2( number )
      ratio = 1.feet * 1.feet
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Area]
    def self.yard2( number )
      ratio = 1.yard * 1.yard
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Area]
    def self.mile2( number )
      ratio = 1.mile * 1.mile
      self.new( number * ratio )
    end


    # @return [Float]
    def to_mm2
      ratio = 1.mm * 1.mm
      @area / ratio
    end

    # @return [Float]
    def to_cm2
      ratio = 1.cm * 1.cm
      @area / ratio
    end

    # @return [Float]
    def to_m2
      ratio = 1.m * 1.m
      @area / ratio
    end

    # @return [Float]
    def to_km2
      ratio = 1.km * 1.km
      @area / ratio
    end


    # @return [Float]
    def to_inch2
      ratio = 1.inch * 1.inch
      @area / ratio
    end

    # @return [Float]
    def to_feet2
      ratio = 1.feet * 1.feet
      @area / ratio
    end

    # @return [Float]
    def to_yard2
      ratio = 1.yard * 1.yard
      @area / ratio
    end

    # @return [Float]
    def to_mile2
      ratio = 1.mile * 1.mile
      @area / ratio
    end


    # @return [String]
    def to_s
      Sketchup.format_area( @area )
    end
    alias :inspect :to_s

    # @return [Integer]
    def to_i
      @area.to_i
    end

    # @return [Float]
    def to_f
      @area.to_f
    end

  end # class Area


  # Model Units set to Meters with precision 0,0:
  #
  #   a1 = Volume.m3( 30 )
  #   => "3 Meters ³"
  #
  #   a2 = Volume.cm3( 2000000 )
  #   => "2 Meters ³"
  #
  #   a3 = a1 + a2
  #   => "5 Meters ³"
  #
  #   Volume.m3( 30 ) * 2
  #   => "60 Meters ³"
  #
  #   Volume.m3( 30 ) / 2
  #   => "15 Meters ³"
  #
  #   length = Volume.m3( 27 ).cubed
  #   => "9,0m"
  #
  #   Volume.new( 10000000 )
  #   => "163,9 Meters ³"
  #
  #   Volume.inch3( 10000000 )
  #   => "163,9 Meters ³"
  #
  #   length = Volume.m3(27) / Area.m3(6)
  #   => "4,5m"
  #
  #   area = Volume.m3(27) / 9.m
  #   => "3 Meters ²"
  class Volume

    include Comparable
    include Locale

    def initialize( number )
      @volume = number.to_f
    end


    # @param [#to_f] number
    #
    # @return [Volume]
    def +( number )
      self.class.new( @volume + number.to_f )
    end

    # @param [#to_f] number
    #
    # @return [Volume]
    def -( number )
      self.class.new( @volume - number.to_f )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def *( number )
      self.class.new( @volume * number )
    end

    # @param [Numeric] number
    #
    # @return [Length] if divided by an +Area+.
    # @return [Area] if divided by a +Length+.
    # @return [Volume] if divided by a +Numeric+ object.
    def /( number )
      if number.is_a?( Length )
        Area.new( @volume / number )
      elsif number.is_a?( Area )
        ( @volume / number.to_f ).to_l
      else
        self.class.new( @volume / number )
      end
    end


    # @param [#to_f] number
    #
    # @return [Volume]
    def <=>( volume )
      @volume <=> volume.to_f
    end


    # @return [Length]
    def cubed
      ( @volume ** ( 1 / 3.0 ) ).to_l
    end


    # @param [Numeric] number
    #
    # @return [Volume]
    def self.mm3( number )
      ratio = 1.mm * 1.mm * 1.mm
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def self.cm3( number )
      ratio = 1.cm * 1.cm * 1.cm
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def self.m3( number )
      ratio = 1.m * 1.m * 1.m
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def self.km3( number )
      ratio = 1.km * 1.km * 1.km
      self.new( number * ratio )
    end


    # @param [Numeric] number
    #
    # @return [Volume]
    def self.inch3( number )
      ratio = 1.inch * 1.inch * 1.inch
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def self.feet3( number )
      ratio = 1.feet * 1.feet * 1.feet
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def self.yard3( number )
      ratio = 1.yard * 1.yard * 1.yard
      self.new( number * ratio )
    end

    # @param [Numeric] number
    #
    # @return [Volume]
    def self.mile3( number )
      ratio = 1.mile * 1.mile * 1.mile
      self.new( number * ratio )
    end


    # @return [Float]
    def to_mm3
      ratio = 1.mm * 1.mm * 1.mm
      @volume / ratio
    end

    # @return [Float]
    def to_cm3
      ratio = 1.cm * 1.cm * 1.cm
      @volume / ratio
    end

    # @return [Float]
    def to_m3
      ratio = 1.m * 1.m * 1.m
      @volume / ratio
    end

    # @return [Float]
    def to_km3
      ratio = 1.km * 1.km * 1.km
      @volume / ratio
    end


    # @return [Float]
    def to_inch3
      ratio = 1.inch * 1.inch * 1.inch
      @volume / ratio
    end

    # @return [Float]
    def to_feet3
      ratio = 1.feet * 1.feet * 1.feet
      @volume / ratio
    end

    # @return [Float]
    def to_yard3
      ratio = 1.yard * 1.yard * 1.yard
      @volume / ratio
    end

    # @return [Float]
    def to_mile3
      ratio = 1.mile * 1.mile * 1.mile
      @volume / ratio
    end


    # @return [String]
    def to_s
      units_options = Sketchup.active_model.options['UnitsOptions']

      # SketchUp ignores "Display units format" for areas and volumes.
      #
      # LengthFormat
      #
      # 0 : Decimal (Display units format)
      # => LengthUnit
      #    0 : Inches
      #    1 : Feet
      #    2 : Millimeters
      #    3 : Centimeters
      #    4 : Meters
      #
      # 1 : Architectural (Force display of 0")
      # => LengthUnit
      #    0 : Inches
      #
      # 2 : Engineering
      # => LengthUnit
      #    0 : Feet
      #
      # 3 : Fractional (Display units format)
      # => LengthUnit
      #    0 : Inches
      #
      case units_options['LengthFormat']

      when Length::Decimal
        case units_options['LengthUnit']
        when Length::Inches
          value = self.to_inch3
        when Length::Feet
          value = self.to_feet3
        when Length::Millimeter
          # (?) SketchUp rounds millimeters squared, but not cubed.
          value = self.to_mm3
        when Length::Centimeter
          value = self.to_cm3
        when Length::Meter
          value = self.to_m3
        end
        index = units_options['LengthUnit']
        postfix = %w{Inches Feet Millimeters Centimeters Meters}[index]
        formatted_value = "#{format_float(value, true)} #{postfix} ³"

      when Length::Architectural
        value = self.to_feet3
        if value < 1.0
          # When we have less than a foot, display inches instead.
          value = self.to_inch3
          formatted_value = "#{format_float(value, true)} Inches ³"
        else
          formatted_value = "#{format_float(value, true)} Feet ³"
        end

      when Length::Engineering
        value = self.to_feet3
        formatted_value = "#{format_float(value, true)} Feet ³"

      when Length::Fractional
        value = self.to_inch3
        formatted_value = "#{format_float(value, true)} Inches ³"

      end # case units_options['LengthFormat']

      # (!) Hack
      # Names of units are probably translated. Extract current units string
      # from Sketchup.format_area(0). Currently overrides the manual formatting.
      # Test if it works properly. Otherwise revert to English.
      # NOTE: Before SketchUp 2014 Sketchup.format_area(0) would yield
      #       "0 Millimeters ²". After that it returned "0 mm²".
      current_unit = Sketchup.format_area(0).match(/^0 (\S+)\s*²/)[1]
      formatted_value = "#{format_float(value, true)} #{current_unit} ³"

      formatted_value
    end
    alias :inspect :to_s

    # @return [Integer]
    def to_i
      @volume.to_i
    end

    # @return [Float]
    def to_f
      @volume.to_f
    end

  end # class Volume

end # module Example
