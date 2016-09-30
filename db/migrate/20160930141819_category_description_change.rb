class CategoryDescriptionChange < Mongoid::Migration
  def self.up

    I18n.locale = :'zh-CN'

    category = Category.where(slug: 'cosmetics').first
    category.desc = "德国有机护肤品，肌肤健康呵护。众多品牌兼顾女士男士、日常保养、夏季防晒和毛发护理。"
    category.save

    category = Category.where(slug: 'medicine').first
    category.desc = "后工业时代的德国: 两倍于中国人口密度和森林覆盖率🌲，喜爱饮酒🍺吃肉🍖也热爱运动🚴🏂🏇的德国人-这个体格强健的民族拥有“战车”的美誉。健康的躯体是德意志民族在竞争中的脊梁和动力，他们对健康保健品的要求是什么呢？－我们看到的答案是科学与自然的结合。"
    category.save

    category = Category.where(slug: 'fashion').first
    category.desc = "德国和时尚？😂 这是两个完全不相干的概念吗？－事实上从德国走出了很多世界顶级的设计师，如Karl Lagerfeld、Jil Sander等等。德国独立设计师的作品，参加派对让闺蜜们猜猜这是谁的作品，下一个Lagerfeld与你一起特立独行ing😉"
    category.save

  end

  def self.down
  end
end
