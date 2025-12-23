import React, { useState, useEffect } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Theme } from './src/Theme';
import { scanQRCode, startRequest } from 'react-native-mivip';

const App = () => {
  const [requestId, setRequestId] = useState('');
  const [isValid, setIsValid] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
    setIsValid(uuidRegex.test(requestId));
  }, [requestId]);

  const handleScanQR = async () => {
    try {
      setLoading(true);
      const result = await scanQRCode();
      Alert.alert('Success', `Verification Result: ${result}`);
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleManualEntry = async () => {
    if (!isValid) return;
    try {
      setLoading(true);
      const result = await startRequest(requestId);
      Alert.alert('Success', `Verification Result: ${result}`);
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.flex}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          {/* Logo Placeholder */}
          <View style={styles.logoContainer}>
            <Text style={styles.logoText}>MITEK</Text>
          </View>

          <Text style={styles.title}>Identity Verification</Text>
          <Text style={styles.subtitle}>
            Complete your verification journey using one of the options below.
          </Text>

          {/* QR Card */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardIcon}>📷</Text>
              <Text style={styles.cardTitle}>Scan QR Code</Text>
            </View>
            <Text style={styles.cardDescription}>
              Scan the QR code from your email or verification portal.
            </Text>
            <TouchableOpacity
              style={styles.primaryButton}
              onPress={handleScanQR}
              disabled={loading}
            >
              <Text style={styles.buttonText}>Scan QR</Text>
            </TouchableOpacity>
          </View>

          <Text style={styles.divider}>— OR —</Text>

          {/* Manual Entry Card */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardIcon}>🔑</Text>
              <Text style={styles.cardTitle}>Enter Request ID</Text>
            </View>
            <Text style={styles.cardDescription}>
              Manually enter your verification Request ID.
            </Text>
            <TextInput
              style={[
                styles.input,
                requestId.length > 0 && {
                  borderColor: isValid ? 'green' : Theme.colors.mitekRed,
                },
              ]}
              placeholder="Enter ID"
              value={requestId}
              onChangeText={setRequestId}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <TouchableOpacity
              style={[
                styles.primaryButton,
                !isValid && styles.disabledButton,
              ]}
              onPress={handleManualEntry}
              disabled={!isValid || loading}
            >
              <Text style={styles.buttonText}>Continue</Text>
            </TouchableOpacity>
          </View>

          {loading && (
            <ActivityIndicator
              size="large"
              color={Theme.colors.mitekRed}
              style={styles.loader}
            />
          )}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Theme.colors.background,
  },
  flex: {
    flex: 1,
  },
  scrollContent: {
    padding: Theme.spacing.l,
    alignItems: 'center',
  },
  logoContainer: {
    height: 60,
    justifyContent: 'center',
    marginBottom: Theme.spacing.l,
  },
  logoText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Theme.colors.mitekBlue,
    letterSpacing: 4,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: Theme.colors.mitekRed,
    textAlign: 'center',
    marginBottom: Theme.spacing.s,
  },
  subtitle: {
    fontSize: 16,
    color: Theme.colors.secondaryText,
    textAlign: 'center',
    marginBottom: Theme.spacing.xl,
  },
  card: {
    width: '100%',
    backgroundColor: Theme.colors.secondaryBackground,
    borderRadius: Theme.borderRadius.l,
    padding: Theme.spacing.l,
    marginBottom: Theme.spacing.m,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Theme.spacing.m,
  },
  cardIcon: {
    fontSize: 24,
    marginRight: Theme.spacing.m,
    color: Theme.colors.mitekRed,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: Theme.colors.text,
  },
  cardDescription: {
    fontSize: 14,
    color: Theme.colors.secondaryText,
    marginBottom: Theme.spacing.l,
  },
  primaryButton: {
    backgroundColor: Theme.colors.mitekRed,
    borderRadius: Theme.borderRadius.m,
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  disabledButton: {
    backgroundColor: Theme.colors.disabled,
  },
  buttonText: {
    color: Theme.colors.white,
    fontSize: 18,
    fontWeight: 'bold',
  },
  divider: {
    color: Theme.colors.secondaryText,
    marginVertical: Theme.spacing.m,
  },
  input: {
    backgroundColor: Theme.colors.white,
    borderWidth: 1,
    borderColor: Theme.colors.disabled,
    borderRadius: Theme.borderRadius.m,
    padding: Theme.spacing.m,
    marginBottom: Theme.spacing.l,
    fontSize: 16,
  },
  loader: {
    marginTop: Theme.spacing.l,
  },
});

export default App;
