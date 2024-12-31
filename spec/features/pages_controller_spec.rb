require 'spec_helper'

describe PagesController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region, state: 'OR')
  end

  describe 'Regionless', type: :feature, js: true do
    it 'shouldnt perform a search if you dont enter search criteria' do
      visit '/map'

      click_on 'location_search_button'

      expect(page.body).to have_content('0 Locations & 0 machines in results')
      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
    end

    it 'only lets you search by one thing at a time, OR address + machine' do
      visit '/map'

      fill_in('by_location_name', with: 'foo')

      fill_in('by_machine_name', with: 'bar')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#address').value).to eq('')

      fill_in('address', with: 'baz')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#by_machine_id', visible: :hidden).value).to eq('')
      expect(find('#by_machine_name').value).to eq('bar')

      fill_in('by_machine_name', with: 'bang')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#address').value).to eq('baz')

      fill_in('by_location_name', with: 'foo')
      expect(find('#by_machine_name').value).to eq('')
      expect(find('#address').value).to eq('')
    end

    it 'lets you search by address and machine and respects if you change or clear out the machine search value' do
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: FactoryBot.create(:machine, name: 'Bawb'))

      visit '/map'

      fill_in('by_machine_name', with: 'Sass')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Sass")]').click

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      expect(page.body).to have_content('Rip City')
      expect(page.body).to_not have_content('No Way')

      fill_in('by_machine_name', with: 'Bawb')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Bawb")]').click

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      expect(page.body).to have_content('No Way')
      expect(page.body).to_not have_content('Rip City')

      fill_in('by_machine_name', with: '')

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      expect(page.body).to have_content('Rip City')
      expect(page.body).to have_content('No Way')
    end

    it 'lets you filter by location type and number of machines with address and machine name' do
      bar_type = FactoryBot.create(:location_type, id: 4, name: 'bar')
      cleo = FactoryBot.create(:location, id: 38, zip: '97203', lat: 45.590502800000, lon: -122.754940100000, name: 'Cleo', location_type: bar_type)
      bawb = FactoryBot.create(:location, id: 39, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Bawb')
      sass = FactoryBot.create(:location, id: 40, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Sass', location_type: bar_type)
      FactoryBot.create(:location_machine_xref, location: sass, machine: FactoryBot.create(:machine, name: 'Solomon', machine_group: nil))

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s), location: cleo)
      end

      25.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 2222 + index, name: 'machine ' + index.to_s), location: sass)
      end

      visit '/map'

      fill_in('address', with: '97203')

      page.find('#form .limit select#by_type_id').click
      select('bar', from: 'by_type_id')

      click_on 'location_search_button'

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      fill_in('address', with: '97203')

      page.find('#form .limit select#by_at_least_n_machines').click
      select('10+', from: 'by_at_least_n_machines')

      click_on 'location_search_button'

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      fill_in('by_machine_name', with: 'Solomon')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Solomon")]').click

      page.find('#form .limit select#by_type_id').click
      select('bar', from: 'by_type_id')

      page.find('#form .limit select#by_at_least_n_machines').click
      select('10+', from: 'by_at_least_n_machines')

      click_on 'location_search_button'

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      page.find('#form .limit select#by_type_id').click
      select('bar', from: 'by_type_id')

      page.find('#form .limit select#by_at_least_n_machines').click
      select('10+', from: 'by_at_least_n_machines')

      click_on 'location_search_button'

      expect(page.body).to have_content('0 Locations & 0 machines in results')
      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")

      visit '/map?by_type_id=4'

      click_on 'location_search_button'

      expect(page).to have_content('0 Locations & 0 machines in results')
      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")

      visit '/map?by_at_least_n_machines=5'

      click_on 'location_search_button'

      expect(page).to have_content('0 Locations & 0 machines in results')
      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
    end

    it 'shows single version checkbox if machine is in a group' do
      @machine_group = FactoryBot.create(:machine_group)
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Dude', machine_group: @machine_group))

      visit '/map'

      fill_in('by_machine_name', with: 'Sass')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Sass")]').click

      expect(page.body).to have_css('#singleVersion', visible: :hidden)

      visit '/map'

      fill_in('by_machine_name', with: 'Dude')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Dude")]').click

      expect(page).to have_content('Exact machine version?')
      expect(page).to have_css('#singleVersion', visible: true)
    end

    it 'respects user_faved filter' do
      user = FactoryBot.create(:user)
      login(user)

      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Foo'))
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Bar'))
      FactoryBot.create(:user_fave_location, location: FactoryBot.create(:location, name: 'Baz'))

      visit '/saved'

      expect(page).to have_content('Foo')
      expect(page).to have_content('Bar')
      expect(page).to_not have_content('Baz')
    end

    it 'lets you search by address -- displays 0 results instead of saying "Not Found"' do
      FactoryBot.create(:location, region: nil, name: 'Troy', zip: '48098', lat: 42.5925, lon: 83.1756)

      visit '/map'

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      expect(page).to have_content('0 Locations & 0 machines in results')
      expect(page).to_not have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
    end

    it 'location autocomplete select ensures you only search by a single location' do
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail', city: 'Portland', state: 'OR')

      visit '/map'

      fill_in('by_location_name', with: 'Rip')
      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }
      find(:xpath, '//div[text()="Rip City Retail (Portland, OR)"]').click

      click_on 'location_search_button'

      expect(find('#search_results')).to have_content('Rip City Retail')
      expect(find('#search_results')).to_not have_content('Rip City Retail SW')
    end

    it 'machine search blanks out machine_id when you search, honors machine_name scope' do
      rip_location = FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      clark_location = FactoryBot.create(:location, region: nil, name: "Clark's Corner")
      renee_location = FactoryBot.create(:location, region: nil, name: "Renee's Rental")
      FactoryBot.create(:location_machine_xref, location: rip_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine, name: 'Sass 2'))
      FactoryBot.create(:location_machine_xref, location: renee_location, machine: FactoryBot.create(:machine, name: 'Bawb'))

      visit '/map'

      fill_in('by_machine_name', with: 'Bawb')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[text()="Bawb"]').click

      click_on 'location_search_button'

      expect(find('#search_results')).to have_content('Renee')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Rip City')

      fill_in('by_location_name', with: "Clark's Corner")

      click_on 'location_search_button'

      expect(find('#search_results')).to_not have_content('Rip City')
      expect(find('#search_results')).to have_content('Clark')
      expect(find('#search_results')).to_not have_content('Renee')

      fill_in('by_machine_name', with: 'Sass')

      click_on 'location_search_button'

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Renee')
    end
  end

  describe 'Events', type: :feature, js: true do
    it 'handles basic event displaying' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today + 1)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 3', start_date: Date.today - 1)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 4')
      FactoryBot.create(:event, region: @region, location: @location, external_location_name: 'External location', name: 'event 5')
      FactoryBot.create(:event, region: @region, external_location_name: 'External location', name: 'event 6')

      visit '/portland/events'

      expect(page).to have_content("event 3 @ Test Location Name\n#{Date.today.strftime('%b %d, %Y')}")
      expect(page).to have_content("event 1 @ Test Location Name\n#{(Date.today + 1).strftime('%b %d, %Y')}")
      expect(page).to have_content('event 2 @ Test Location Name')
    end

    it 'is case insensitive for region name' do
      chicago_region = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')
      FactoryBot.create(:event, region: chicago_region, name: 'event 1', start_date: Date.today)

      visit '/CHICAGO/events'

      expect(page).to have_content('event 1')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8, end_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end

    it 'displays events that have no start/end date (typically league stuff)' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: nil, end_date: nil)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to have_content('event 2')
    end
  end

  describe 'High roller list', type: :feature, js: true do
    it 'should have intro text that displays correct number of locations and machines for a region' do
      chicago_region = FactoryBot.create(:region, name: 'chicago')
      portland_location = FactoryBot.create(:location, region: @region)
      chicago_location = FactoryBot.create(:location, region: chicago_region)

      machine = FactoryBot.create(:machine)

      portland_lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine)
      another_portland_lmx = FactoryBot.create(:location_machine_xref, location: portland_location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: chicago_location, machine: machine)

      ssw_user = FactoryBot.create(:user, username: 'ssw')
      rtgt_user = FactoryBot.create(:user, username: 'rtgt')
      FactoryBot.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 100, user: ssw_user)
      FactoryBot.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 90, user: rtgt_user)
      FactoryBot.create(:machine_score_xref, location_machine_xref: another_portland_lmx, score: 200, user: ssw_user)

      visit '/portland/high_rollers'

      expect(page).to have_content('ssw: with 2 scores')
      expect(page).to have_content('rtgt: with 1 scores')
    end
  end

  describe 'Top 10 Machine Counts', type: :feature, js: true do
    it 'shows the top 10 machine counts on the about page' do
      11.times do |machine_name_counter|
        machine_name_counter.times do
          FactoryBot.create(:location_machine_xref, location: @location, machine: Machine.where(name: "Machine#{machine_name_counter}").first_or_create)
        end
      end

      visit '/portland/about'

      expect(page).to have_content("Machine10: with 10 machines\nMachine9: with 9 machines\nMachine8: with 8 machines\nMachine7: with 7 machines\nMachine6: with 6 machines\nMachine5: with 5 machines\nMachine4: with 4 machines\nMachine3: with 3 machines\nMachine2: with 2 machines\nMachine1: with 1 machines")
    end
  end

  describe 'Links', type: :feature, js: true do
    it 'shows links in a region' do
      chicago = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')

      FactoryBot.create(:region_link_xref, region: @region, description: 'foo')
      FactoryBot.create(:region_link_xref, region: chicago, name: 'chicago link 1', category: 'main links', sort_order: 2, description: 'desc1')
      FactoryBot.create(:region_link_xref, region: chicago, name: 'cool link 1', category: 'cool links', sort_order: 1, description: 'desc2')

      visit '/chicago/about'

      expect(page).to have_content("cool links\ncool link 1\ndesc2\nmain links\nchicago link 1\ndesc1")
    end

    it 'sort order does not cause headers to display twice' do
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 1', category: 'main links', sort_order: 2)
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 2', category: 'main links', sort_order: 1)
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 3', category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content("main links\nlink 2\ndesc\nlink 1\ndesc\nother category\nlink 3\ndesc")
    end

    it 'makes a default link category called "Links"' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 1', description: nil, category: nil)
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 2', description: nil, category: '')
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 3', description: nil, category: ' ')
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 4', description: nil, category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content("Links\nlink 1\nlink 2\nlink 3\nother category\nlink 4")
    end

    it 'Mixing sort_order and nil sort_order links does not error' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'Minnesota Pinball - The "Pin Cities"', url: 'https://somesite.site', description: 'Your best source for everything pinball in Minnesota!  Events, leagues, locations, games and more!', category: 'Pinball Map Links', sort_order: 1)
      FactoryBot.create(:region_link_xref, region: @region, name: 'Pinball Map Store', url: 'http://blog.pinballmap.com', description: 'News, questions, feelings.', category: 'Pinball Map Links', sort_order: nil)

      visit "/#{@region.name}/about"

      expect(page).to have_content("Links\nPinball Map Store\nNews, questions, feelings.\nMinnesota Pinball - The \"Pin Cities\"\nYour best source for everything pinball in Minnesota! Events, leagues, locations, games and more!")
    end
  end

  describe 'Location suggestions', type: :feature, js: true do
    it 'limits state dropdown to unique states within a region' do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', created_at: '02/02/2016')
      login(@user)
      chicago = FactoryBot.create(:region, name: 'chicago')

      FactoryBot.create(:location, region: @region, state: 'WA')
      FactoryBot.create(:location, region: chicago, state: 'IL')
      login

      visit "/#{@region.name}/suggest"
      expect(page).to have_select('location_state', options: ['', 'OR', 'WA'])
    end

    it 'does not show form if not logged in' do
      visit "/#{@region.name}/suggest"
      expect(page).to have_content('To suggest a new location you first need to login. Thank you!')
    end
  end

  describe 'Homepage', type: :feature, js: true do
    it 'shows the proper page title' do
      visit '/'

      expect(page).to have_title('Pinball Map')
      expect(page).not_to have_title('App')
    end

    it 'does not show a random location link if there are no locations in the region' do
      toronto = FactoryBot.create(:region, name: 'toronto', full_name: 'Toronto')

      visit '/toronto'

      expect(page).not_to have_content('Or click here for a random location!')

      FactoryBot.create(:location, region: toronto)
      FactoryBot.create(:location, region: toronto)
      FactoryBot.create(:location, region: toronto)

      visit '/toronto'

      expect(page).to have_content('Or click here for a random location!')
    end
  end

  describe 'Pages', type: :feature, js: true do
    it 'show the proper page title' do
      FactoryBot.create(:user, id: 111)
      visit '/app'
      expect(page).to have_title('App')

      visit '/donate'
      expect(page).to have_title('Donate')

      visit '/store'
      expect(page).to have_title('Store')

      visit '/faq'
      expect(page).to have_title('FAQ')

      visit '/users/111/profile'
      expect(page).to have_title('User Profile')

      visit "/#{@region.name}/about"
      expect(page).to have_title('About')

      visit "/#{@region.name}/suggest"
      expect(page).to have_title('Suggest')

      visit "/#{@region.name}/events"
      expect(page).to have_title('Events')

      visit "/#{@region.name}/high_rollers"
      expect(page).to have_title('High Scores')

      visit '/map/?by_location_id=1234'
      expect(page).to have_title('Pinball Map')

      visit "/map/?by_location_id=#{@location.id}"
      expect(page).to have_title('Test Location Name')
    end
  end

  describe 'Landing page for a region', type: :feature, js: true do
    it 'shows the proper location and machine counts in the intro text' do
      chicago = FactoryBot.create(:region, name: 'chicago')
      machine = FactoryBot.create(:machine)

      FactoryBot.create(:location_machine_xref, location: @location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region), machine: machine)

      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: chicago), machine: machine)

      visit '/portland'

      expect(page).to have_content('2 locations and 2 machines')
    end

    it 'shows the proper page title' do
      visit '/portland'

      expect(page).to have_title('Portland Pinball Map')
      expect(page).not_to have_title('Apps')
    end
  end

  describe 'admin', type: :feature, js: true do
    it 'presents a link to the admin pages if you are an admin' do
      visit '/'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Login')

      visit '/portland'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Login')

      user = FactoryBot.create(:user)
      login(user)

      visit '/'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Logout')

      visit '/portland'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Logout')

      user = FactoryBot.create(:user, region_id: @region.id)
      login(user)

      visit '/'
      find('#menu_button').click

      expect(page).to have_content('Admin')
      expect(page).to have_content('Logout')

      visit '/portland'
      find('#menu_button').click

      expect(page).to have_content('Admin')
      expect(page).to have_content('Logout')
    end
  end

  describe 'get_a_profile', type: :feature, js: true do
    it 'redirects you to your user profile page if you are logged in' do
      visit '/inspire_profile'

      expect(page).to have_current_path(inspire_profile_path)

      user = FactoryBot.create(:user, id: 10)
      login(user)

      visit '/inspire_profile'

      expect(page).to have_current_path(profile_user_path(user.id))
    end
  end
end
