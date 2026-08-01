import 'dart:math';
import 'package:flutter/foundation.dart';

/// A simple matrix class for Kalman Filter operations
class Mat {
  final int rows;
  final int cols;
  final List<List<double>> data;

  Mat(this.rows, this.cols, [double initialValue = 0.0])
      : data = List.generate(rows, (_) => List.filled(cols, initialValue));

  Mat.fromList(this.data)
      : rows = data.length,
        cols = data.isNotEmpty ? data[0].length : 0;

  double get(int r, int c) => data[r][c];
  void set(int r, int c, double val) => data[r][c] = val;

  Mat add(Mat other) {
    Mat res = Mat(rows, cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        res.data[i][j] = data[i][j] + other.data[i][j];
      }
    }
    return res;
  }

  Mat sub(Mat other) {
    Mat res = Mat(rows, cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        res.data[i][j] = data[i][j] - other.data[i][j];
      }
    }
    return res;
  }

  Mat mul(Mat other) {
    Mat res = Mat(rows, other.cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < other.cols; j++) {
        double sum = 0.0;
        for (int k = 0; k < cols; k++) {
          sum += data[i][k] * other.data[k][j];
        }
        res.data[i][j] = sum;
      }
    }
    return res;
  }

  Mat transpose() {
    Mat res = Mat(cols, rows);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        res.data[j][i] = data[i][j];
      }
    }
    return res;
  }

  static Mat eye(int size) {
    Mat res = Mat(size, size);
    for (int i = 0; i < size; i++) {
      res.data[i][i] = 1.0;
    }
    return res;
  }

  // A very simple Gaussian elimination for inversion
  Mat inverse() {
    if (rows != cols) throw Exception("Matrix must be square");
    int n = rows;
    Mat a = Mat.fromList(List.generate(n, (i) => List.from(data[i])));
    Mat res = Mat.eye(n);

    for (int i = 0; i < n; i++) {
      // Find pivot
      int maxRow = i;
      double maxVal = a.data[i][i].abs();
      for (int k = i + 1; k < n; k++) {
        if (a.data[k][i].abs() > maxVal) {
          maxVal = a.data[k][i].abs();
          maxRow = k;
        }
      }

      // Swap
      if (maxRow != i) {
        List<double> tempA = a.data[i];
        a.data[i] = a.data[maxRow];
        a.data[maxRow] = tempA;

        List<double> tempRes = res.data[i];
        res.data[i] = res.data[maxRow];
        res.data[maxRow] = tempRes;
      }

      double pivot = a.data[i][i];
      if (pivot.abs() < 1e-9) {
        // Singular matrix, return identity as fallback
        return Mat.eye(n); 
      }

      // Scale row i
      for (int j = 0; j < n; j++) {
        a.data[i][j] /= pivot;
        res.data[i][j] /= pivot;
      }

      // Eliminate
      for (int k = 0; k < n; k++) {
        if (k == i) continue;
        double factor = a.data[k][i];
        for (int j = 0; j < n; j++) {
          a.data[k][j] -= factor * a.data[i][j];
          res.data[k][j] -= factor * res.data[i][j];
        }
      }
    }
    return res;
  }
}

/// A standard Kalman Filter for bounding box tracking (ByteTrack / SORT)
/// State: [cx, cy, aspect_ratio, height, vx, vy, va, vh]
class KalmanFilter {
  late Mat _x; // State estimate
  late Mat _P; // Error covariance
  late Mat _F; // State transition model
  late Mat _H; // Observation model
  late Mat _R; // Observation noise covariance
  late Mat _Q; // Process noise covariance

  static const double _stdWeightPosition = 1.0 / 20;
  static const double _stdWeightVelocity = 1.0 / 160;

  KalmanFilter() {
    int ndim = 4;
    double dt = 1.0;
    
    _F = Mat.eye(8);
    for (int i = 0; i < ndim; i++) {
      _F.set(i, i + ndim, dt);
    }
    
    _H = Mat(4, 8);
    for (int i = 0; i < 4; i++) {
      _H.set(i, i, 1.0);
    }
  }

  void initiate(List<double> measurement) {
    _x = Mat(8, 1);
    for (int i = 0; i < 4; i++) {
      _x.set(i, 0, measurement[i]);
    }

    double cx = measurement[0];
    double cy = measurement[1];
    double a = measurement[2];
    double h = measurement[3];

    List<double> std = [
      2 * _stdWeightPosition * h,
      2 * _stdWeightPosition * h,
      1e-2,
      2 * _stdWeightPosition * h,
      10 * _stdWeightVelocity * h,
      10 * _stdWeightVelocity * h,
      1e-5,
      10 * _stdWeightVelocity * h
    ];

    _P = Mat.eye(8);
    for (int i = 0; i < 8; i++) {
      _P.set(i, i, std[i] * std[i]);
    }
  }

  void predict() {
    double h = _x.get(3, 0);
    List<double> std = [
      _stdWeightPosition * h,
      _stdWeightPosition * h,
      1e-2,
      _stdWeightPosition * h,
      _stdWeightVelocity * h,
      _stdWeightVelocity * h,
      1e-5,
      _stdWeightVelocity * h
    ];
    _Q = Mat.eye(8);
    for (int i = 0; i < 8; i++) {
      _Q.set(i, i, std[i] * std[i]);
    }

    _x = _F.mul(_x);
    _P = _F.mul(_P).mul(_F.transpose()).add(_Q);
  }

  void update(List<double> measurement) {
    double h = _x.get(3, 0);
    List<double> std = [
      _stdWeightPosition * h,
      _stdWeightPosition * h,
      1e-1,
      _stdWeightPosition * h
    ];
    _R = Mat.eye(4);
    for (int i = 0; i < 4; i++) {
      _R.set(i, i, std[i] * std[i]);
    }

    Mat z = Mat(4, 1);
    for (int i = 0; i < 4; i++) {
      z.set(i, 0, measurement[i]);
    }

    Mat y = z.sub(_H.mul(_x));
    Mat S = _H.mul(_P).mul(_H.transpose()).add(_R);
    Mat K = _P.mul(_H.transpose()).mul(S.inverse());

    _x = _x.add(K.mul(y));
    _P = Mat.eye(8).sub(K.mul(_H)).mul(_P);
  }

  List<double> getState() {
    return [
      _x.get(0, 0),
      _x.get(1, 0),
      _x.get(2, 0),
      _x.get(3, 0),
    ];
  }
}
