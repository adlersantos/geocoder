require 'test_helper'

class GeocoderTest < Test::Unit::TestCase

  def setup
    Geocoder::Configuration.lookup = :google
  end

  def test_fetch_coordinates
    v = Venue.new(*venue_params(:msg))
    assert_equal [40.750354, -73.993371], v.fetch_coordinates
    assert_equal [40.750354, -73.993371], [v.latitude, v.longitude]
  end

  # sanity check
  def test_distance_between
    assert_equal 69, Geocoder::Calculations.distance_between(0,0, 0,1).round
  end

  # sanity check
  def test_geographic_center
    assert_equal [0.0, 0.5],
      Geocoder::Calculations.geographic_center([[0,0], [0,1]])
    assert_equal [0.0, 1.0],
      Geocoder::Calculations.geographic_center([[0,0], [0,1], [0,2]])
  end

  def test_exception_raised_for_unconfigured_geocoding
    l = Landmark.new("Mount Rushmore", 43.88, -103.46)
    assert_raises Geocoder::ConfigurationError do
      l.fetch_coordinates
    end
  end

  def test_result_address_components_of_type
    results = Geocoder.search("Madison Square Garden, New York, NY")
    assert_equal "Manhattan",
      results.first.address_components_of_type(:sublocality).first['long_name']
  end

  def test_does_not_choke_on_nil_address
    v = Venue.new("Venue", nil)
    assert_nothing_raised do
      v.fetch_coordinates
    end
  end

  # --- Yahoo ---
  def test_yahoo_result_components
    Geocoder::Configuration.lookup = :yahoo
    results = Geocoder.search("Madison Square Garden, New York, NY")
    assert_equal "10001", results.first.postal
  end

  def test_yahoo_address_formatting
    Geocoder::Configuration.lookup = :yahoo
    results = Geocoder.search("Madison Square Garden, New York, NY")
    assert_equal "Madison Square Garden, New York, NY  10001, United States",
      results.first.address
  end

  # --- FreeGeoIp ---
  def test_freegeoip_result_on_ip_address_search
    results = Geocoder.search("74.200.247.59")
    assert results.first.is_a?(Geocoder::Result::Freegeoip)
  end

  def test_freegeoip_result_components
    results = Geocoder.search("74.200.247.59")
    assert_equal "Plano, TX 75093, United States", results.first.address
  end

  # --- search queries ---
  def test_ip_address_detection
    assert Geocoder.send(:ip_address?, "232.65.123.94")
    assert Geocoder.send(:ip_address?, "666.65.123.94") # technically invalid
    assert !Geocoder.send(:ip_address?, "232.65.123.94.43")
    assert !Geocoder.send(:ip_address?, "232.65.123")
  end

  def test_blank_query_detection
    assert Geocoder.send(:blank_query?, nil)
    assert Geocoder.send(:blank_query?, "")
    assert Geocoder.send(:blank_query?, ", , (-)")
    assert !Geocoder.send(:blank_query?, "a")
  end
end
