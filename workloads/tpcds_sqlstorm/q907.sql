WITH domain_sales AS (
  SELECT
    lower(split(c.c_email_address, '@')[2]) AS domain,
    cs.cs_ext_sales_price AS sales,
    i.i_brand,
    i.i_item_desc
  FROM
    customer c
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE c.c_email_address IS NOT NULL
),
word_agg AS (
  SELECT
    ds.domain,
    ds.i_brand,
    lower(word) AS word,
    count(*) AS cnt,
    sum(ds.sales) AS total_sales
  FROM
    domain_sales ds
    CROSS JOIN UNNEST(split(regexp_replace(ds.i_item_desc, '[^A-Za-z0-9]', ' '), ' ')) AS t(word)
  WHERE word <> ''
  GROUP BY ds.domain, ds.i_brand, lower(word)
),
word_stats AS (
  SELECT
    domain,
    i_brand,
    word,
    cnt,
    total_sales,
    row_number() OVER (PARTITION BY domain, i_brand ORDER BY cnt DESC) AS rn
  FROM word_agg
),
agg_per_domain AS (
  SELECT
    domain,
    sum(total_sales) AS domain_total_sales,
    length(domain) AS domain_len,
    substr(domain, 1, 5) AS domain_prefix,
    regexp_extract(domain, '\\\\.(\\\\w+)$', 1) AS top_level_domain,
    array_join(
      array_agg(
        concat(i_brand, ':', word, '(', CAST(cnt AS varchar), ')')
        ORDER BY i_brand, cnt DESC
      ),
      ' | '
    ) AS brand_word_summary,
    concat(domain, '-', CAST(length(domain) AS varchar), '-', coalesce(regexp_extract(domain, '\\\\.(\\\\w+)$', 1), '')) AS domain_tag,
    reverse(domain) AS reversed_domain
  FROM word_stats
  WHERE rn <= 3
  GROUP BY
    domain,
    length(domain),
    substr(domain, 1, 5),
    regexp_extract(domain, '\\\\.(\\\\w+)$', 1),
    reverse(domain)
)
SELECT
  domain,
  domain_len,
  domain_prefix,
  coalesce(top_level_domain, '') AS tld,
  domain_total_sales,
  brand_word_summary,
  domain_tag,
  reversed_domain
FROM agg_per_domain
ORDER BY domain_total_sales DESC
LIMIT 20
