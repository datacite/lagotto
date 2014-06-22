# encoding: UTF-8
# Load private sources
viewed = Group.find_or_create_by_name(name: 'viewed', display_name: 'Viewed')
saved = Group.find_or_create_by_name(name: 'saved', display_name: 'Saved')
discussed = Group.find_or_create_by_name(name: 'discussed', display_name: 'Discussed')
cited = Group.find_or_create_by_name(name: 'cited', display_name: 'Cited')
recommended = Group.find_or_create_by_name(name: 'recommended', display_name: 'Recommended')
other = Group.find_or_create_by_name(name: 'other', display_name: 'Other')

counter = Counter.find_or_create_by_name(
      :name => 'counter',
      :display_name => 'Counter',
      :description => 'Usage stats from the PLOS website',
      :queueable => false,
      :group_id => viewed.id)
wos = Wos.find_or_create_by_name(
      :name => 'wos',
      :display_name => 'Web of Science',
      :description => 'Web of Science is an online academic citation index.',
      :private => 1,
      :workers => 1,
      :group_id => cited.id)
f1000 = F1000.find_or_create_by_name(
      :name => 'f1000',
      :display_name => 'F1000Prime',
      :description => 'Post-publication peer review of the biomedical literature.',
      :queueable => false,
      :group_id => recommended.id)
figshare = Figshare.find_or_create_by_name(
      :name => 'figshare',
      :display_name => 'Figshare',
      :description => 'Figures, tables and supplementary files hosted by figshare',
      :group_id => viewed.id)
articleconverage = ArticleCoverage.find_or_create_by_name(
      :name => 'articlecoverage',
      :display_name => 'Article Coverage',
      :description => 'Article Coverage',
      :group_id => discussed.id)
articlecoveragecurated = ArticleCoverageCurated.find_or_create_by_name(
      :name => 'articlecoveragecurated',
      :display_name => 'Article Coverage Curated',
      :description => 'Article Coverage Curated',
      :group_id => discussed.id)
plos_comments = PlosComments.find_or_create_by_name(
      :name => 'plos_comments',
      :display_name => 'Journal Comments',
      :description => 'Comments from the PLOS website.',
      :group_id => discussed.id)

    # These sources are retired, but we need to keep them around for the data we collected
connotea = Connotea.find_or_create_by_name(
      :name => 'connotea',
      :display_name => 'Connotea',
      :description => 'A free online reference management service for scientists, ' \
                      'researchers, and clinicians (discontinued March 2013)',
      :group_id => other.id)
postgenomic = Postgenomic.find_or_create_by_name(
      :name => 'postgenomic',
      :display_name => 'Postgenomic',
      :description => 'A science blog aggregator (discontinued)',
      :group_id => other.id)
bloglines = Bloglines.find_or_create_by_name(
      :name => 'bloglines',
      :display_name => 'Bloglines',
      :description => 'A science blog aggregator (discontinued)',
      :group_id => other.id)
biod = Biod.find_or_create_by_name(
      :name => 'biod',
      :display_name => 'Biod',
      :description => 'Usage stats from the PLOS biodiversity hub',
      :queueable => false,
      :group_id => other.id)
