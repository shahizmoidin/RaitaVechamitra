import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:raitavechamitra/utils/localization.dart'; // Import for localization

class Scheme {
  final String name;
  final String description;
  final String link;
  final String category;
  bool isFavorite;

  Scheme({
    required this.name,
    required this.description,
    required this.link,
    required this.category,
    this.isFavorite = false,
  });
}

class SchemeScreen extends StatefulWidget {
  @override
  _SchemeScreenState createState() => _SchemeScreenState();
}

class _SchemeScreenState extends State<SchemeScreen> {
  final List<Scheme> _schemes = [
    Scheme(
      name: 'pm_kisanname', // Localized name key
      description: 'pm_kisandescription', // Localized description key
      link: 'https://pmkisan.gov.in/',
      category: 'income_support',
    ),
    Scheme(
      name: 'karnataka_raithaname', // Localized name key
      description: 'karnataka_raithadescription', // Localized description key
      link: 'https://raitamitra.karnataka.gov.in/',
      category: 'income_support',
    ),
    Scheme(
      name: 'rkvyname', // Localized name key
      description: 'rkvydescription', // Localized description key
      link: 'https://rkvy.nic.in/',
      category: 'income_support',
    ),
    Scheme(
      name: 'mukhyamantri_krishiname', // Localized name key
      description: 'mukhyamantri_krishidescription', // Localized description key
      link: 'https://krishi.bih.nic.in/',
      category: 'income_support',
    ),
    Scheme(
      name: 'atal_solarname', // Localized name key
      description: 'atal_solardescription', // Localized description key
      link: 'https://mahadiscom.in/atal-solar-krishi-pump-yojana/',
      category: 'income_support',
    ),
    // Crop Insurance Schemes
    Scheme(
      name: 'pmfbyname', // Localized name key
      description: 'pmfbydescription', // Localized description key
      link: 'https://pmfby.gov.in/',
      category: 'crop_insurance',
    ),
    Scheme(
      name: 'wbcisname', // Localized name key
      description: 'wbcisdescription', // Localized description key
      link: 'https://www.agri-insurance.gov.in/',
      category: 'crop_insurance',
    ),
    // Soil and Irrigation Schemes
    Scheme(
      name: 'soil_healthname', // Localized name key
      description: 'soil_healthdescription', // Localized description key
      link: 'https://soilhealth.dac.gov.in/',
      category: 'soil_irrigation',
    ),
    Scheme(
      name: 'krishi_bhagyaname', // Localized name key
      description: 'krishi_bhagyadescription', // Localized description key
      link: 'https://raitamitra.karnataka.gov.in/Pages/krishi-bhagya.aspx',
      category: 'soil_irrigation',
    ),
    // Equipment Schemes
    Scheme(
      name: 'farm_mechanizationname', // Localized name key
      description: 'farm_mechanizationdescription', // Localized description key
      link: 'https://agrimachinery.nic.in/',
      category: 'equipment',
    ),
    Scheme(
      name: 'custom_hiringname', // Localized name key
      description: 'custom_hiringdescription', // Localized description key
      link: 'https://agrimachinery.nic.in/',
      category: 'equipment',
    ),
    // Horticulture Schemes
    Scheme(
      name: 'national_horticulturename', // Localized name key
      description: 'national_horticulturedescription', // Localized description key
      link: 'https://nhm.nic.in/',
      category: 'horticulture',
    ),
    // Food Security Schemes
    Scheme(
      name: 'pm_garibname', // Localized name key
      description: 'pm_garibdescription', // Localized description key
      link: 'https://pmgky.gov.in/',
      category: 'food_security',
    ),
    // Livestock and Animal Husbandry Schemes
    Scheme(
      name: 'national_livestockname', // Localized name key
      description: 'national_livestockdescription', // Localized description key
      link: 'https://nlm.gov.in/',
      category: 'livestock',
    ),
    // Organic Farming Schemes
    Scheme(
      name: 'pkvyname', // Localized name key
      description: 'pkvydescription', // Localized description key
      link: 'https://agricoop.nic.in/',
      category: 'organic_farming',
    ),



    
    // Add more schemes following this pattern if needed
  ];

  List<Scheme> _filteredSchemes = [];
  bool _isFavoriteFilter = false;
  String _searchQuery = '';
  String _selectedCategory = 'all_categories';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _filteredSchemes = List.from(_schemes);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteSchemes = prefs.getStringList('favorite_schemes') ?? [];
    setState(() {
      for (var scheme in _schemes) {
        scheme.isFavorite = favoriteSchemes.contains(scheme.name);
      }
    });
  }

  Future<void> _toggleFavorite(Scheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      scheme.isFavorite = !scheme.isFavorite;
    });

    List<String> favoriteSchemes = _schemes.where((s) => s.isFavorite).map((s) => s.name).toList();
    await prefs.setStringList('favorite_schemes', favoriteSchemes);
  }

  void _filterSchemes() {
    setState(() {
      _filteredSchemes = _schemes.where((scheme) {
        final matchesQuery = scheme.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            scheme.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFavorite = !_isFavoriteFilter || scheme.isFavorite;
        final matchesCategory = _selectedCategory == 'all_categories' || scheme.category == _selectedCategory;
        return matchesQuery && matchesFavorite && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('schemetitle')),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: Icon(_isFavoriteFilter ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _isFavoriteFilter = !_isFavoriteFilter;
              });
              _filterSchemes();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryDropdown(context),
          _buildSearchBar(context),
          Expanded(
            child: _filteredSchemes.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).translate('no_schemes_found'),
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSchemes.length,
                    itemBuilder: (context, index) {
                      final scheme = _filteredSchemes[index];
                      return _buildSchemeCard(context, scheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: _selectedCategory,
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
            _filterSchemes();
          });
        },
        items: [
          'all_categories',
          'income_support',
          'crop_insurance',
          'soil_irrigation',
          'equipment',
          'horticulture',
          'food_security',
          'livestock',
          'organic_farming',
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              AppLocalizations.of(context).translate(value),
              style: TextStyle(fontSize: 16, color: Colors.green[800]),
            ),
          );
        }).toList(),
        isExpanded: true,
        underline: Container(),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('search_schemes'),
          prefixIcon: Icon(Icons.search, color: Colors.green[800]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterSchemes();
          });
        },
      ),
    );
  }

  Widget _buildSchemeCard(BuildContext context, Scheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(Icons.description, color: Colors.green[700], size: 40),
        title: Text(
          AppLocalizations.of(context).translate(scheme.name),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[900]),
        ),
        subtitle: Text(
          AppLocalizations.of(context).translate(scheme.description),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            scheme.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: scheme.isFavorite ? Colors.red : Colors.grey,
          ),
          onPressed: () => _toggleFavorite(scheme),
        ),
        onTap: () => _showSchemeDetails(context, scheme),
      ),
    );
  }

  void _showSchemeDetails(BuildContext context, Scheme scheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate(scheme.name),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).translate(scheme.description), style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text(AppLocalizations.of(context).translate('more_info'), style: TextStyle(fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WebViewScreen(url: scheme.link)),
                );
              },
              child: Text(
                scheme.link,
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('close')),
          ),
        ],
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;

  WebViewScreen({required this.url});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('webview_title')),
        backgroundColor: Colors.green[800],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
      ),
    );
  }
}
