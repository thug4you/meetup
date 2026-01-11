import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../../../data/models/place.dart';
import '../../../core/theme/app_theme.dart';

class MapViewWidget extends StatefulWidget {
  final Place place;
  final double? latitude;
  final double? longitude;
  final double zoom;
  final bool interactive;

  const MapViewWidget({
    super.key,
    required this.place,
    this.latitude,
    this.longitude,
    this.zoom = 14,
    this.interactive = false,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  late String _mapViewId;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapViewId = 'yandex-map-view-${DateTime.now().millisecondsSinceEpoch}';
    _initializeMap();
  }

  void _initializeMap() {
    // Регистрируем HTML элемент для карты
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _mapViewId,
      (int viewId) {
        final element = html.DivElement()
          ..id = 'map-view-$viewId'
          ..style.width = '100%'
          ..style.height = '100%';

        // Инициализация карты после загрузки
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _createYandexMap(element.id);
          }
        });

        return element;
      },
    );
  }

  void _createYandexMap(String containerId) {
    final lat = widget.latitude ?? widget.place.latitude;
    final lng = widget.longitude ?? widget.place.longitude;
    final zoom = widget.zoom;
    final interactive = widget.interactive;

    // Создаем карту через Yandex Maps API
    js.context.callMethod('eval', ['''
      (function() {
        ymaps.ready(function() {
          var map = new ymaps.Map('$containerId', {
            center: [$lat, $lng],
            zoom: $zoom,
            controls: ${interactive ? "['zoomControl', 'geolocationControl']" : "[]"}
          }, {
            suppressMapOpenBlock: true
          });

          ${!interactive ? 'map.behaviors.disable("scrollZoom");' : ''}
          ${!interactive ? 'map.behaviors.disable("drag");' : ''}
          ${!interactive ? 'map.behaviors.disable("multiTouch");' : ''}

          var placemark = new ymaps.Placemark([$lat, $lng], {
            balloonContent: '${widget.place.name}'
          }, {
            preset: 'islands#redDotIcon'
          });

          map.geoObjects.add(placemark);

          // Сохраняем ссылку на карту
          window['yandexMapView_$containerId'] = map;
        });
      })();
    ''']);

    setState(() {
      _isMapReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            HtmlElementView(viewType: _mapViewId),
            if (!_isMapReady)
              Container(
                color: AppTheme.backgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Очищаем карту
    js.context.callMethod('eval', ['''
      (function() {
        var map = window['yandexMapView_map-view-*'];
        if (map) {
          map.destroy();
          window['yandexMapView_map-view-*'] = null;
        }
      })();
    ''']);
    super.dispose();
  }
}
