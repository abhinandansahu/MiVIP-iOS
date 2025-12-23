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
  useColorScheme,
  Image,
} from 'react-native';
import { Theme } from './src/Theme';
import { scanQRCode, startRequest } from 'react-native-mivip';

const App = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const colors = isDarkMode ? Theme.dark : Theme.light;

  const [requestId, setRequestId] = useState('');
  const [isValid, setIsValid] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
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

  const dynamicStyles = StyleSheet.create({
    container: {
      backgroundColor: colors.background,
    },
    title: {
      color: isDarkMode ? colors.white : colors.mitekRed,
    },
    subtitle: {
      color: colors.secondaryText,
    },
    card: {
      backgroundColor: colors.secondaryBackground,
    },
    cardTitle: {
      color: colors.text,
    },
    cardDescription: {
      color: colors.secondaryText,
    },
    divider: {
      color: colors.secondaryText,
    },
    input: {
      backgroundColor: colors.inputBackground,
      color: colors.text,
      borderColor: colors.inputBorder,
    },
    logoText: {
        color: isDarkMode ? colors.white : colors.mitekBlue,
    }
  });

  return (
    <SafeAreaView style={[styles.container, dynamicStyles.container]}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.flex}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View style={styles.logoContainer}>
            <Image 
              source={require('./src/assets/mitek_logo.png')} 
              style={[styles.logoImage, isDarkMode && { tintColor: colors.white }]} 
              resizeMode="contain" 
            />
          </View>

          <Text style={[styles.title, dynamicStyles.title]}>Identity Verification</Text>
          <Text style={[styles.subtitle, dynamicStyles.subtitle]}>
            Complete your verification journey using one of the options below.
          </Text>

          {/* QR Card */}
          <View style={[styles.card, dynamicStyles.card]}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardIcon}>📷</Text>
              <Text style={[styles.cardTitle, dynamicStyles.cardTitle]}>Scan QR Code</Text>
            </View>
            <Text style={[styles.cardDescription, dynamicStyles.cardDescription]}>
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

          <Text style={[styles.divider, dynamicStyles.divider]}>— OR —</Text>

          {/* Manual Entry Card */}
          <View style={[styles.card, dynamicStyles.card]}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardIcon}>🔑</Text>
              <Text style={[styles.cardTitle, dynamicStyles.cardTitle]}>Enter Request ID</Text>
            </View>
            <Text style={[styles.cardDescription, dynamicStyles.cardDescription]}>
              Manually enter your verification Request ID.
            </Text>
            <TextInput
              style={[
                styles.input,
                dynamicStyles.input,
                requestId.length > 0 && {
                  borderColor: isValid ? 'green' : colors.mitekRed,
                },
              ]}
              placeholder="Enter ID"
              placeholderTextColor={colors.secondaryText}
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
              color={colors.mitekRed}
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
  logoImage: {
    width: 200,
    height: 60,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: Theme.spacing.s,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: Theme.spacing.xl,
  },
  card: {
    width: '100%',
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
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  cardDescription: {
    fontSize: 14,
    marginBottom: Theme.spacing.l,
  },
  primaryButton: {
    backgroundColor: '#EE2C46', // Always Red
    borderRadius: Theme.borderRadius.m,
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  disabledButton: {
    backgroundColor: '#CCCCCC',
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: 'bold',
  },
  divider: {
    marginVertical: Theme.spacing.m,
  },
  input: {
    borderWidth: 1,
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
