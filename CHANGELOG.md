[0.1.0]
* Initial version for Tandoor with 1.4.9
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.4.9)

[0.2.0]
* Fix media upload

[0.3.0]
* Update Tandoor to 1.4.10
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.4.10)
* fixed release notifications (thanks to @gabe565 #2437)
* updated django and fixed file upload (thanks to ambroisie #2458)
* updated translations

[0.4.0]
* Update Tandoor to 1.4.11
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.4.11)
* added noindex to header to prevent indexing content by search engines (thanks to screendriver #2435)
* added ability to set gunicorn logging parameter to .env (thanks to gloriousDan #2470)
* improved plugin functionality

[1.0.0]
* First stable package release
* Update Tandoor to 1.4.12
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.4.12)
* added allow plugins to define dropdown nav entries
* fixed json importer not working since its missing source_url attribute
* updated open data plugin

[1.1.0]
* Update Tandoor to 1.5.0
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.5.0)
* added unit conversion
* tandoor can now automatically convert your ingredients to different units
* conversion between all common metric and imperial units works automatically (within either weight or volume)
* conversions to convert between weight and volume for certain foods or to convert between special units (like pcs or your favourite cup) can be added manually
* currently conversions are used for property calculation, in the future many more features are possible with this
* added food properties
* every food can have different properties like nutrition, price, allergens or whatever you like to track
* these properties are then automatically calculated for every individual recipe
* the URL importer now automatically imports nutrition information properties from websites if possible
* in the future this can be integrated into different modules like shopping (price) or meal plans (nutrition)
* added open data importer
* The Tandoor Open Data Project aims to provide a community curated list of basic data for your tandoor instance
* Feel free to participate in its growth to help everyone improve their Tandoor workflows
* improved food editor (much cleaner, supports new features)
* added admin options to delete unused steps and ingredients (thanks to @smilerz #2488)
* added Norwegian to available languages #2487
* fixed hide bottom navigation in print view (thanks to jwr1 #2478)
* fixed url import edge case with arrays as names #2429
* fixed HowToSteps in Nextcloud Cookbook imports #2428
* fixed edge cases with the rezeptsuite importer #2467
* fixed recipesage servings and time import
* improved lots of functionality regarding plugins (still otherwise undocumented as very early stages)

[1.1.1]
* Update Tandoor to 1.5.1
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.5.1)
* fixed meal plan view
* fixed error with keyword automation

[1.1.2]
* Update Tandoor to 1.5.2
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.5.2)
* fixed merging foods would delete all food properties #2513
* fixed uniqueness check failing with open data slug models #2512

[1.1.3]
* Update Tandoor to 1.5.3
* [Full changelog](https://github.com/TandoorRecipes/recipes/releases/tag/1.5.3)
* improved don't show the properties view if no property types are present in space
* improved automatically adding schema specific attributes if not present in json importer #2426
* fixed issue with not begin able to add decimal amounts in property values #2518
* fixed issue when creating food and adding properties at the same time
* fixed text color in nav to light for some background colors
* fixed broken images could fail the tandoor importer
* added TrueNAS Portainer installation instructions to the docs (thanks to 16cdlogan #2517)

