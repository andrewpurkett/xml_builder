defmodule XmlBuilderTest do
  use ExUnit.Case
  doctest XmlBuilder

	@unescaped_delimiter Application.fetch_env!(:xml_builder, :indentation)
	@unescaped_line_delimiter Application.fetch_env!(:xml_builder, :line)

	@delimiter Macro.unescape_string(@unescaped_delimiter)
	@line_delimiter Macro.unescape_string(@unescaped_line_delimiter)

  import XmlBuilder, only: [doc: 1, doc: 2, doc: 3]

  test "empty element" do
    assert doc(:person) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person/>|
  end

  test "element with content" do
    assert doc(:person, "Josh") == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person>Josh</person>|
  end

  test "element with attributes" do
    assert doc(:person, %{occupation: "Developer", city: "Montreal"}) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person city="Montreal" occupation="Developer"/>|
    assert doc(:person, %{}) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person/>|
  end

  test "element with attributes and content" do
    assert doc(:person, %{occupation: "Developer", city: "Montreal"}, "Josh") == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person city="Montreal" occupation="Developer">Josh</person>|
    assert doc(:person, %{occupation: "Developer", city: "Montreal"}, nil) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person city="Montreal" occupation="Developer"/>|
    assert doc(:person, %{}, "Josh") == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person>Josh</person>|
    assert doc(:person, %{}, nil) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person/>|
  end

  test "element with children" do
    assert doc(:person, [{:name, %{id: 123}, "Josh"}]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person>#{@line_delimiter}#{@delimiter}<name id="123">Josh</name>#{@line_delimiter}</person>|
    assert doc(:person, [{:first_name, "Josh"}, {:last_name, "Nussbaum"}]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person>#{@line_delimiter}#{@delimiter}<first_name>Josh</first_name>#{@line_delimiter}#{@delimiter}<last_name>Nussbaum</last_name>#{@line_delimiter}</person>|
  end

  test "element with attributes and children" do
    assert doc(:person, %{id: 123}, [{:name, "Josh"}]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person id="123">#{@line_delimiter}#{@delimiter}<name>Josh</name>#{@line_delimiter}</person>|
    assert doc(:person, %{id: 123}, [{:first_name, "Josh"}, {:last_name, "Nussbaum"}]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person id="123">#{@line_delimiter}#{@delimiter}<first_name>Josh</first_name>#{@line_delimiter}#{@delimiter}<last_name>Nussbaum</last_name>#{@line_delimiter}</person>|
  end

  test "children elements" do
    assert doc([{:name, %{id: 123}, "Josh"}]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<name id="123">Josh</name>|
    assert doc([{:first_name, "Josh"}, {:last_name, "Nussbaum"}]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<first_name>Josh</first_name>#{@line_delimiter}<last_name>Nussbaum</last_name>|
  end

  test "quoting and escaping attributes" do
    assert element(:person, %{height: 12}) == ~s|<person height="12"/>|
    assert element(:person, %{height: ~s|10'|}) == ~s|<person height="10'"/>|
    assert element(:person, %{height: ~s|10"|}) == ~s|<person height='10"'/>|
    assert element(:person, %{height: ~s|<10'5"|}) == ~s|<person height="&lt;10'5&quot;"/>|
  end

  test "escaping content" do
    assert element(:person, "Josh") == "<person>Josh</person>"
    assert element(:person, "<Josh>") == "<person>&lt;Josh&gt;</person>"
    assert element(:data, "1 <> 2 & 2 <> 3") == "<data>1 &lt;&gt; 2 &amp; 2 &lt;&gt; 3</data>"
  end

  test "wrap content inside cdata and skip escaping" do
    assert element(:person, {:cdata, "john & <is ok>"}) == "<person><![CDATA[john & <is ok>]]></person>"
  end

  test "multi level indentation" do
    assert doc([person: [first: "Josh", last: "Nussbaum"]]) == ~s|<?xml version="1.0" encoding="UTF-8" ?>#{@line_delimiter}<person>#{@line_delimiter}#{@delimiter}<first>Josh</first>#{@line_delimiter}#{@delimiter}<last>Nussbaum</last>#{@line_delimiter}</person>|
  end

  def element(name, arg),
    do: XmlBuilder.element(name, arg) |> XmlBuilder.generate

  def element(name, attrs, content),
    do: XmlBuilder.element(name, attrs, content) |> XmlBuilder.generate
end
