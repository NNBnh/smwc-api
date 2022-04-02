#!/usr/bin/env ruby

require "open-uri"
require "nokogiri"
require "json"

types = {
  "Standard: Easy" => 1,
  "Standard: Normal" => 2,
  "Standard: Hard" => 3,
  "Standard: Very Hard" => 4,
  "Kaizo: Beginner" => 5,
  "Kaizo: Intermediate" => 6,
  "Kaizo: Expert" => 7,
  "Tool-Assisted: Kaizo" => 8,
  "Tool-Assisted: Pit" => 9,
  "Misc.: Troll" => 10
}

(1..36).to_a.map { |page|
  [
    URI.open("https://www.smwcentral.net/?p=section&s=smwhacks&u=0&g=0&n=#{page}&o=date&d=desc"),
    URI.open("https://www.smwcentral.net/?p=section&s=smwhacks&u=0&g=1&n=#{page}&o=date&d=desc")
  ]
  .map { |document| Nokogiri::HTML.parse(document) }
}.map { |list, gallery|
  list.css("#list_content table tr")[1..].map { |data|
    {
      id: data.css("td a")[0].attributes["href"].value.tr("^0-9", "").to_i,
      name: data.css("td a")[0].children.text,
      demo: data.css("td")[1].children.text.strip == "Yes",
      featured: data.css("td")[2].children.text.strip == "Yes",
      length: data.css("td")[3].children.text.strip.to_i,
      types: data.css("td")[4].children.text.split(",").map { |type| types[type.strip] },
      author: data.css("td")[5].css("a").map { |author|
        {
          id: author.attributes["href"].value.tr("^0-9", "").to_i,
          name: author.children[0].text,
          style: author.attributes["style"].value
        }
      },
      rating: data.css("td")[6].children.text.strip.to_f,
      size: data.css("td")[7].children.text.strip,
      downloads: data.css("span")[-1].children.text.split[0].to_i,
      file: "https:" + data.css("a")[-1].attributes["href"].value
    }
  } => info

  gallery.css(".screenshot").each_with_index { |screenshot, index|
    info[index][:screenshot] = "https:" + screenshot.attributes["src"].value
  }

  info
}
.flatten.to_json.then { |data|
  File.write("smw.json", data)
}
